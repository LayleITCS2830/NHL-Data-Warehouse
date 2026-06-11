"""Load NHL player game statistics into the data warehouse.

This script stages boxscore player stats in staging.player_game_stats_raw,
executes fact.P_LOAD_FACT_PLAYER_GAME_STATS, and validates that no duplicate
player/game/team rows exist in the fact table. The staging table is truncated
before each load.
"""

from __future__ import annotations

import argparse
from datetime import date, timedelta
import json
import os
import sys
from typing import Any

import pyodbc

from nhl_dw_etl import (
    DEFAULT_BOXSCORE_ENDPOINT_TEMPLATE,
    DEFAULT_SCHEDULE_ENDPOINT_TEMPLATE,
    SOURCE_SYSTEM,
    build_connection_string,
    count_rows,
    date_range,
    fetch_json,
    mark_batch_failed,
    parse_date,
    start_load_batch,
    toi_to_seconds,
    truncate_staging_table,
)


def parse_player_stats(
    raw_player: dict[str, Any], game_id: int, team_id: int
) -> dict[str, Any] | None:
    # Boxscore groups can contain non-player placeholders; skip rows without ids.
    player_id = raw_player.get("playerId")
    if player_id is None:
        return None

    # Preserve source JSON and normalize measures for staging.player_game_stats_raw.
    return {
        "raw_json": json.dumps(raw_player, ensure_ascii=False, sort_keys=True),
        "game_id": game_id,
        "player_id": int(player_id),
        "team_id": team_id,
        "goals": raw_player.get("goals"),
        "assists": raw_player.get("assists"),
        "shots": raw_player.get("sog"),
        "hits": raw_player.get("hits"),
        "blocks": raw_player.get("blockedShots"),
        "penalty_minutes": raw_player.get("pim"),
        "time_on_ice_seconds": toi_to_seconds(raw_player.get("toi")),
    }


def fetch_game_ids(
    schedule_endpoint_template: str, start_date: date, end_date: date
) -> list[int]:
    # Build the set of completed games that should have boxscore statistics.
    game_ids: set[int] = set()

    for schedule_date in date_range(start_date, end_date):
        # Request one schedule window for each date in the requested range.
        schedule_url = schedule_endpoint_template.format(
            game_date=schedule_date.strftime("%Y-%m-%d")
        )
        schedule = fetch_json(schedule_url)

        for schedule_day in schedule.get("gameWeek", []):
            if not isinstance(schedule_day, dict):
                continue

            for raw_game in schedule_day.get("games", []):
                if not isinstance(raw_game, dict):
                    continue
                # Only final games should be loaded into the player game stats fact.
                if raw_game.get("gameState") not in {"FINAL", "OFF"}:
                    continue
                if raw_game.get("id") is not None:
                    game_ids.add(int(raw_game["id"]))

    return sorted(game_ids)


def fetch_player_game_stats(
    boxscore_endpoint_template: str, game_ids: list[int]
) -> list[dict[str, Any]]:
    # Fetch and flatten boxscore player stats for each selected game.
    stats_rows: list[dict[str, Any]] = []

    for game_id in game_ids:
        # One boxscore response contains both away and home player stats.
        boxscore_url = boxscore_endpoint_template.format(game_id=game_id)
        boxscore = fetch_json(boxscore_url)
        player_stats = boxscore.get("playerByGameStats", {})
        teams = {
            "awayTeam": (boxscore.get("awayTeam") or {}).get("id"),
            "homeTeam": (boxscore.get("homeTeam") or {}).get("id"),
        }

        for team_side, team_id in teams.items():
            # Skip malformed boxscores that do not include a team identifier.
            if team_id is None:
                continue

            team_stats = player_stats.get(team_side, {})
            if not isinstance(team_stats, dict):
                continue

            # NHL boxscores group skaters and goalies separately by team side.
            for roster_group in ("forwards", "defense", "goalies"):
                raw_players = team_stats.get(roster_group, [])
                if not isinstance(raw_players, list):
                    continue

                for raw_player in raw_players:
                    if not isinstance(raw_player, dict):
                        continue

                    parsed_stats = parse_player_stats(raw_player, game_id, int(team_id))
                    if parsed_stats is not None:
                        stats_rows.append(parsed_stats)

    return stats_rows


def insert_staging_rows(
    cursor: pyodbc.Cursor, load_batch_id: str, stats_rows: list[dict[str, Any]]
) -> int:
    # Stage parsed player game stat rows with the current audit batch id.
    insert_sql = """
        INSERT INTO staging.player_game_stats_raw
                (source_system,
                load_batch_id,
                raw_json,
                game_id,
                player_id,
                team_id,
                goals,
                assists,
                shots,
                hits,
                blocks,
                penalty_minutes,
                time_on_ice_seconds)
        VALUES  (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    """

    rows = [
        (
            SOURCE_SYSTEM,
            load_batch_id,
            stats["raw_json"],
            stats["game_id"],
            stats["player_id"],
            stats["team_id"],
            stats["goals"],
            stats["assists"],
            stats["shots"],
            stats["hits"],
            stats["blocks"],
            stats["penalty_minutes"],
            stats["time_on_ice_seconds"],
        )
        for stats in stats_rows
    ]

    if not rows:
        return 0

    # Bulk insert is important because one game can produce many player rows.
    cursor.fast_executemany = True
    cursor.executemany(insert_sql, rows)
    return len(rows)


def execute_fact_load(cursor: pyodbc.Cursor, load_batch_id: str) -> None:
    # Move the staged player game stats into fact.player_game_stats_fact.
    cursor.execute(
        "EXEC fact.P_LOAD_FACT_PLAYER_GAME_STATS @load_batch_id = ?;",
        load_batch_id,
    )


def get_duplicate_player_game_stats(cursor: pyodbc.Cursor) -> int:
    # Count duplicate player/game/team combinations created by the load.
    cursor.execute(
        """
        SELECT  COUNT(*) AS duplicate_count
        FROM    (
                    SELECT  game_key,
                            player_key,
                            team_key
                    FROM    fact.player_game_stats_fact
                    GROUP BY game_key,
                            player_key,
                            team_key
                    HAVING  COUNT(*) > 1
                ) d;
        """
    )
    return int(cursor.fetchone().duplicate_count)


def run(
    schedule_endpoint_template: str,
    boxscore_endpoint_template: str,
    start_date: date,
    end_date: date,
    explicit_game_ids: list[int],
) -> int:
    # Use explicit game ids when supplied; otherwise discover final games by date.
    game_ids = explicit_game_ids or fetch_game_ids(
        schedule_endpoint_template, start_date, end_date
    )
    stats_rows = fetch_player_game_stats(boxscore_endpoint_template, game_ids)

    load_batch_id: str | None = None
    connection = pyodbc.connect(build_connection_string())

    try:
        cursor = connection.cursor()

        # Start audit tracking, refresh stats staging, and commit staged rows.
        stats_count_before = count_rows(cursor, "fact.player_game_stats_fact")
        load_batch_id = start_load_batch(cursor)
        truncate_staging_table(cursor, "staging.player_game_stats_raw")
        insert_count = insert_staging_rows(cursor, load_batch_id, stats_rows)
        connection.commit()

        # Execute the warehouse upsert procedure for the staged batch.
        execute_fact_load(cursor, load_batch_id)
        connection.commit()

        # Collect row-count and duplicate-key validation results.
        stats_count_after = count_rows(cursor, "fact.player_game_stats_fact")
        duplicate_count = get_duplicate_player_game_stats(cursor)

        print(f"Load batch: {load_batch_id}")
        print(f"Game IDs parsed: {len(game_ids)}")
        print(f"API player game stat rows parsed: {len(stats_rows)}")
        print(f"Staging rows inserted: {insert_count}")
        print(f"Player game stats fact count before: {stats_count_before}")
        print(f"Player game stats fact count after: {stats_count_after}")
        print(f"Duplicate player/game/team check rows: {duplicate_count}")

        return 1 if duplicate_count else 0
    except Exception as exc:
        # Roll back open work and mark the audit batch failed when possible.
        connection.rollback()
        if load_batch_id is not None:
            mark_batch_failed(connection.cursor(), load_batch_id, str(exc))
            connection.commit()
        raise
    finally:
        connection.close()


def parse_game_ids(value: str | None) -> list[int]:
    # Normalize comma-separated CLI or environment filters into integer ids.
    if not value:
        return []
    return [int(game_id.strip()) for game_id in value.split(",") if game_id.strip()]


def parse_args() -> argparse.Namespace:
    # Allow endpoint, date range, and game id overrides for targeted loads.
    parser = argparse.ArgumentParser(
        description="Load NHL player game stats into the warehouse."
    )
    parser.add_argument(
        "--schedule-endpoint-template",
        default=os.getenv("NHL_SCHEDULE_ENDPOINT_TEMPLATE", DEFAULT_SCHEDULE_ENDPOINT_TEMPLATE),
        help="NHL schedule endpoint template with {game_date}.",
    )
    parser.add_argument(
        "--boxscore-endpoint-template",
        default=os.getenv("NHL_BOXSCORE_ENDPOINT_TEMPLATE", DEFAULT_BOXSCORE_ENDPOINT_TEMPLATE),
        help="NHL boxscore endpoint template with {game_id}.",
    )
    parser.add_argument(
        "--start-date",
        default=os.getenv("NHL_START_DATE", (date.today() - timedelta(days=7)).isoformat()),
        help="First schedule date to inspect in YYYY-MM-DD format.",
    )
    parser.add_argument(
        "--end-date",
        default=os.getenv("NHL_END_DATE", date.today().isoformat()),
        help="Last schedule date to inspect in YYYY-MM-DD format.",
    )
    parser.add_argument(
        "--game-ids",
        default=os.getenv("NHL_GAME_IDS"),
        help="Optional comma-separated game ids. When supplied, date range is ignored.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    # CLI entry point: convert exceptions into a process failure code.
    args = parse_args()
    try:
        sys.exit(
            run(
                args.schedule_endpoint_template,
                args.boxscore_endpoint_template,
                parse_date(args.start_date),
                parse_date(args.end_date),
                parse_game_ids(args.game_ids),
            )
        )
    except Exception as error:
        print(f"Player game stats ETL failed: {error}", file=sys.stderr)
        sys.exit(1)
