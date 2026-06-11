"""Run all NHL data warehouse Python ETL processes in dependency order.

The source ETL scripts stage NHL API data and execute their matching warehouse
load procedures. The stored-procedure-only runner can be included when an
explicit replay from the latest staging batches is needed.
"""

from __future__ import annotations

import argparse
from collections.abc import Callable
from dataclasses import dataclass
from datetime import date, timedelta
import os
import sys

import load_games
import load_player_game_stats
import load_players
import load_teams
import run_load_procedures
from nhl_dw_etl import (
    DEFAULT_BOXSCORE_ENDPOINT_TEMPLATE,
    DEFAULT_ROSTER_ENDPOINT_TEMPLATE,
    DEFAULT_SCHEDULE_ENDPOINT_TEMPLATE,
    DEFAULT_TEAMS_ENDPOINT,
    parse_date,
)


@dataclass(frozen=True)
class EtlStep:
    # Store the display name and callable for one pipeline step.
    name: str
    execute: Callable[[], int]


def build_steps(args: argparse.Namespace) -> list[EtlStep]:
    # Run source ETL in dependency order: dimensions first, then facts.
    steps = [
        EtlStep(
            "Team dimension ETL",
            lambda: load_teams.run(args.teams_endpoint),
        ),
        EtlStep(
            "Player dimension ETL",
            lambda: load_players.run(
                args.teams_endpoint,
                args.roster_endpoint_template,
                load_players.parse_team_abbrevs(args.team_abbrevs),
            ),
        ),
        EtlStep(
            "Game fact ETL",
            lambda: load_games.run(
                args.schedule_endpoint_template,
                parse_date(args.start_date),
                parse_date(args.end_date),
            ),
        ),
        EtlStep(
            "Player game stats fact ETL",
            lambda: load_player_game_stats.run(
                args.schedule_endpoint_template,
                args.boxscore_endpoint_template,
                parse_date(args.stats_start_date),
                parse_date(args.stats_end_date),
                load_player_game_stats.parse_game_ids(args.game_ids),
            ),
        ),
    ]

    if args.include_load_procedures:
        # Optional replay is explicit because source ETL scripts already load targets.
        steps.append(
            EtlStep(
                "Stored procedure load replay",
                run_load_procedures.run,
            )
        )

    return steps


def run(args: argparse.Namespace) -> int:
    # Execute each step sequentially and stop at the first nonzero result.
    for step_number, step in enumerate(build_steps(args), start=1):
        print(f"[{step_number}] Starting {step.name}")
        result = step.execute()
        if result != 0:
            print(f"[{step_number}] {step.name} failed with exit code {result}")
            return result
        print(f"[{step_number}] Completed {step.name}")

    print("All requested NHL data warehouse Python ETL processes completed.")
    return 0


def parse_args() -> argparse.Namespace:
    # Expose the same endpoint and filter options used by the individual loaders.
    parser = argparse.ArgumentParser(
        description="Run all NHL data warehouse Python ETL processes in order."
    )
    parser.add_argument(
        "--teams-endpoint",
        default=os.getenv("NHL_TEAMS_ENDPOINT", DEFAULT_TEAMS_ENDPOINT),
        help="NHL team reference endpoint URL.",
    )
    parser.add_argument(
        "--roster-endpoint-template",
        default=os.getenv(
            "NHL_ROSTER_ENDPOINT_TEMPLATE",
            DEFAULT_ROSTER_ENDPOINT_TEMPLATE,
        ),
        help="NHL roster endpoint template with {team_abbrev}.",
    )
    parser.add_argument(
        "--schedule-endpoint-template",
        default=os.getenv(
            "NHL_SCHEDULE_ENDPOINT_TEMPLATE",
            DEFAULT_SCHEDULE_ENDPOINT_TEMPLATE,
        ),
        help="NHL schedule endpoint template with {game_date}.",
    )
    parser.add_argument(
        "--boxscore-endpoint-template",
        default=os.getenv(
            "NHL_BOXSCORE_ENDPOINT_TEMPLATE",
            DEFAULT_BOXSCORE_ENDPOINT_TEMPLATE,
        ),
        help="NHL boxscore endpoint template with {game_id}.",
    )
    parser.add_argument(
        "--team-abbrevs",
        default=os.getenv("NHL_TEAM_ABBREVS"),
        help="Optional comma-separated team abbreviations to load, such as TOR,BOS.",
    )
    parser.add_argument(
        "--start-date",
        default=os.getenv(
            "NHL_START_DATE",
            load_games.default_season_start().isoformat(),
        ),
        help="First schedule date for game loading in YYYY-MM-DD format.",
    )
    parser.add_argument(
        "--end-date",
        default=os.getenv("NHL_END_DATE", date.today().isoformat()),
        help="Last schedule date for game loading in YYYY-MM-DD format.",
    )
    parser.add_argument(
        "--stats-start-date",
        default=os.getenv(
            "NHL_STATS_START_DATE",
            os.getenv(
                "NHL_START_DATE",
                (date.today() - timedelta(days=7)).isoformat(),
            ),
        ),
        help="First schedule date for player game stats loading in YYYY-MM-DD format.",
    )
    parser.add_argument(
        "--stats-end-date",
        default=os.getenv(
            "NHL_STATS_END_DATE",
            os.getenv("NHL_END_DATE", date.today().isoformat()),
        ),
        help="Last schedule date for player game stats loading in YYYY-MM-DD format.",
    )
    parser.add_argument(
        "--game-ids",
        default=os.getenv("NHL_GAME_IDS"),
        help="Optional comma-separated game ids for player game stats loading.",
    )
    parser.add_argument(
        "--include-load-procedures",
        action="store_true",
        help="Replay warehouse load procedures from the latest staging batches after source ETL completes.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    # CLI entry point: convert exceptions into a process failure code.
    try:
        sys.exit(run(parse_args()))
    except Exception as error:
        print(f"Master ETL failed: {error}", file=sys.stderr)
        sys.exit(1)
