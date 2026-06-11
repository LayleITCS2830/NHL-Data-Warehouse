"""Load NHL game records into the data warehouse.

This script stages schedule game records in staging.game_raw, executes
fact.P_LOAD_FACT_GAME, and validates that no duplicate source games exist in
fact.game_fact. The staging table is truncated before each load.
"""

from __future__ import annotations

import argparse
from datetime import date
import json
import os
import sys
from typing import Any

import pyodbc

from nhl_dw_etl import (
    DEFAULT_SCHEDULE_ENDPOINT_TEMPLATE,
    SOURCE_SYSTEM,
    build_connection_string,
    count_rows,
    date_range,
    fetch_json,
    mark_batch_failed,
    parse_date,
    start_load_batch,
    truncate_staging_table,
)


def default_season_start(today: date | None = None) -> date:
    # Default game loads to the active NHL season starting September 1.
    current_date = today or date.today()
    season_start_year = current_date.year if current_date.month >= 9 else current_date.year - 1
    return date(season_start_year, 9, 1)


def parse_game(raw_game: dict[str, Any], game_date: date) -> dict[str, Any]:
    # Extract game identity and nested team result details from the schedule record.
    game_id = raw_game.get("id")
    home_team = raw_game.get("homeTeam") or {}
    away_team = raw_game.get("awayTeam") or {}

    if game_id is None:
        raise ValueError(f"Game record is missing id: {raw_game}")

    # Preserve source JSON and normalize values for staging.game_raw.
    return {
        "raw_json": json.dumps(raw_game, ensure_ascii=False, sort_keys=True),
        "game_id": int(game_id),
        "game_date": game_date,
        "season": str(raw_game.get("season")) if raw_game.get("season") is not None else None,
        "game_type": str(raw_game.get("gameType")) if raw_game.get("gameType") is not None else None,
        "home_team_id": home_team.get("id"),
        "away_team_id": away_team.get("id"),
        "home_goals": home_team.get("score"),
        "away_goals": away_team.get("score"),
        "home_shots": home_team.get("sog"),
        "away_shots": away_team.get("sog"),
    }


def fetch_games(
    schedule_endpoint_template: str, start_date: date, end_date: date
) -> list[dict[str, Any]]:
    # Deduplicate games because the NHL weekly schedule endpoint can overlap dates.
    games_by_id: dict[int, dict[str, Any]] = {}

    for schedule_date in date_range(start_date, end_date):
        # Request one schedule window for each date in the requested range.
        schedule_url = schedule_endpoint_template.format(
            game_date=schedule_date.strftime("%Y-%m-%d")
        )
        schedule = fetch_json(schedule_url)
        game_week = schedule.get("gameWeek", [])
        if not isinstance(game_week, list):
            continue

        # Walk each returned schedule day and parse its game list.
        for schedule_day in game_week:
            if not isinstance(schedule_day, dict):
                continue

            raw_games = schedule_day.get("games", [])
            if not isinstance(raw_games, list):
                continue

            schedule_game_date = parse_date(schedule_day["date"])
            for raw_game in raw_games:
                if isinstance(raw_game, dict):
                    # Last write wins for duplicated game ids with the same source data.
                    parsed_game = parse_game(raw_game, schedule_game_date)
                    games_by_id[parsed_game["game_id"]] = parsed_game

    return list(games_by_id.values())


def insert_staging_rows(
    cursor: pyodbc.Cursor, load_batch_id: str, games: list[dict[str, Any]]
) -> int:
    # Stage parsed game rows with the current audit batch id.
    insert_sql = """
        INSERT INTO staging.game_raw
                (source_system,
                load_batch_id,
                raw_json,
                game_id,
                game_date,
                season,
                game_type,
                home_team_id,
                away_team_id,
                home_goals,
                away_goals,
                home_shots,
                away_shots)
        VALUES  (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    """

    rows = [
        (
            SOURCE_SYSTEM,
            load_batch_id,
            game["raw_json"],
            game["game_id"],
            game["game_date"],
            game["season"],
            game["game_type"],
            game["home_team_id"],
            game["away_team_id"],
            game["home_goals"],
            game["away_goals"],
            game["home_shots"],
            game["away_shots"],
        )
        for game in games
    ]

    if not rows:
        return 0

    # Bulk insert is useful for multi-day schedule windows.
    cursor.fast_executemany = True
    cursor.executemany(insert_sql, rows)
    return len(rows)


def execute_fact_load(cursor: pyodbc.Cursor, load_batch_id: str) -> None:
    # Move the staged game records into fact.game_fact.
    cursor.execute("EXEC fact.P_LOAD_FACT_GAME @load_batch_id = ?;", load_batch_id)


def get_duplicate_games(cursor: pyodbc.Cursor) -> list[tuple[int, int]]:
    # Return any duplicate source game keys created by the load.
    cursor.execute(
        """
        SELECT  game_id,
                COUNT(*) AS game_count
        FROM    fact.game_fact
        GROUP BY game_id
        HAVING  COUNT(*) > 1;
        """
    )
    return [(int(row.game_id), int(row.game_count)) for row in cursor.fetchall()]


def run(schedule_endpoint_template: str, start_date: date, end_date: date) -> int:
    # Fetch and normalize schedule data before opening the warehouse transaction.
    games = fetch_games(schedule_endpoint_template, start_date, end_date)

    load_batch_id: str | None = None
    connection = pyodbc.connect(build_connection_string())

    try:
        cursor = connection.cursor()

        # Start audit tracking, refresh game staging, and commit staged rows.
        game_count_before = count_rows(cursor, "fact.game_fact")
        load_batch_id = start_load_batch(cursor)
        truncate_staging_table(cursor, "staging.game_raw")
        insert_count = insert_staging_rows(cursor, load_batch_id, games)
        connection.commit()

        # Execute the warehouse upsert procedure for the staged batch.
        execute_fact_load(cursor, load_batch_id)
        connection.commit()

        # Collect row-count and duplicate-key validation results.
        game_count_after = count_rows(cursor, "fact.game_fact")
        duplicate_games = get_duplicate_games(cursor)

        print(f"Load batch: {load_batch_id}")
        print(f"API games parsed: {len(games)}")
        print(f"Staging rows inserted: {insert_count}")
        print(f"Game fact count before: {game_count_before}")
        print(f"Game fact count after: {game_count_after}")
        print(f"Duplicate game check rows: {len(duplicate_games)}")

        if duplicate_games:
            # A nonzero return code lets schedulers fail the job on validation errors.
            for game_id, game_count in duplicate_games:
                print(f"Duplicate game_id {game_id}: {game_count} rows")
            return 1

        return 0
    except Exception as exc:
        # Roll back open work and mark the audit batch failed when possible.
        connection.rollback()
        if load_batch_id is not None:
            mark_batch_failed(connection.cursor(), load_batch_id, str(exc))
            connection.commit()
        raise
    finally:
        connection.close()


def parse_args() -> argparse.Namespace:
    # Allow schedule endpoint and date range overrides for targeted loads.
    parser = argparse.ArgumentParser(description="Load NHL games into the warehouse.")
    parser.add_argument(
        "--schedule-endpoint-template",
        default=os.getenv("NHL_SCHEDULE_ENDPOINT_TEMPLATE", DEFAULT_SCHEDULE_ENDPOINT_TEMPLATE),
        help="NHL schedule endpoint template with {game_date}.",
    )
    parser.add_argument(
        "--start-date",
        default=os.getenv("NHL_START_DATE", default_season_start().isoformat()),
        help="First schedule date to load in YYYY-MM-DD format. Defaults to September 1 for the active NHL season.",
    )
    parser.add_argument(
        "--end-date",
        default=os.getenv("NHL_END_DATE", date.today().isoformat()),
        help="Last schedule date to load in YYYY-MM-DD format.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    # CLI entry point: convert exceptions into a process failure code.
    args = parse_args()
    try:
        sys.exit(
            run(
                args.schedule_endpoint_template,
                parse_date(args.start_date),
                parse_date(args.end_date),
            )
        )
    except Exception as error:
        print(f"Game ETL failed: {error}", file=sys.stderr)
        sys.exit(1)
