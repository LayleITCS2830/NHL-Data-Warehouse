"""Load NHL team records into the data warehouse.

This script calls the NHL team endpoint, stages the response in staging.team_raw,
executes dimension.P_LOAD_DIM_TEAM, and validates that no duplicate source teams
exist in dimension.team_dim.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from typing import Any

import pyodbc
import requests


DEFAULT_TEAMS_ENDPOINT = "https://api.nhle.com/stats/rest/en/team"
SOURCE_SYSTEM = "NHL API"


def build_connection_string() -> str:
    connection_string = os.getenv("NHL_DW_CONNECTION_STRING")
    if connection_string:
        return connection_string

    server = os.getenv("NHL_DW_SQL_SERVER", "localhost")
    database = os.getenv("NHL_DW_DATABASE", "NHLDataWarehouse")
    driver = os.getenv("NHL_DW_ODBC_DRIVER", "ODBC Driver 18 for SQL Server")
    trusted_connection = os.getenv("NHL_DW_TRUSTED_CONNECTION", "yes")
    trust_server_certificate = os.getenv("NHL_DW_TRUST_SERVER_CERTIFICATE", "yes")

    return (
        f"DRIVER={{{driver}}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"Trusted_Connection={trusted_connection};"
        f"TrustServerCertificate={trust_server_certificate};"
    )


def fetch_teams(endpoint: str) -> list[dict[str, Any]]:
    response = requests.get(endpoint, timeout=30)
    response.raise_for_status()
    payload = response.json()

    teams = payload.get("data")
    if not isinstance(teams, list):
        raise ValueError("NHL team endpoint response did not include a data list.")

    return teams


def parse_team(raw_team: dict[str, Any]) -> dict[str, Any]:
    team_id = raw_team.get("id")
    team_name = raw_team.get("fullName")

    if team_id is None or team_name is None:
        raise ValueError(f"Team record is missing id or fullName: {raw_team}")

    return {
        "raw_json": json.dumps(raw_team, ensure_ascii=False, sort_keys=True),
        "team_id": int(team_id),
        "team_name": str(team_name),
        "team_abbreviation": raw_team.get("triCode") or raw_team.get("rawTricode"),
        "conference": raw_team.get("conferenceName"),
        "division": raw_team.get("divisionName"),
    }


def start_load_batch(cursor: pyodbc.Cursor) -> str:
    cursor.execute(
        """
        DECLARE @load_batch_id UNIQUEIDENTIFIER;

        EXEC audit.P_START_LOAD_BATCH
            @source_system = ?,
            @load_batch_id = @load_batch_id OUTPUT;

        SELECT CONVERT(VARCHAR(36), @load_batch_id) AS load_batch_id;
        """,
        SOURCE_SYSTEM,
    )
    row = cursor.fetchone()
    if row is None:
        raise RuntimeError("audit.P_START_LOAD_BATCH did not return a load_batch_id.")

    return row.load_batch_id


def insert_staging_rows(
    cursor: pyodbc.Cursor, load_batch_id: str, teams: list[dict[str, Any]]
) -> int:
    insert_sql = """
        INSERT INTO staging.team_raw
                (source_system,
                load_batch_id,
                raw_json,
                team_id,
                team_name,
                team_abbreviation,
                conference,
                division)
        VALUES  (?, ?, ?, ?, ?, ?, ?, ?);
    """

    rows = [
        (
            SOURCE_SYSTEM,
            load_batch_id,
            team["raw_json"],
            team["team_id"],
            team["team_name"],
            team["team_abbreviation"],
            team["conference"],
            team["division"],
        )
        for team in teams
    ]

    cursor.fast_executemany = True
    cursor.executemany(insert_sql, rows)
    return len(rows)


def execute_dimension_load(cursor: pyodbc.Cursor, load_batch_id: str) -> None:
    cursor.execute("EXEC dimension.P_LOAD_DIM_TEAM @load_batch_id = ?;", load_batch_id)


def get_team_count(cursor: pyodbc.Cursor) -> int:
    cursor.execute("SELECT COUNT(*) AS team_count FROM dimension.team_dim;")
    return int(cursor.fetchone().team_count)


def get_duplicate_teams(cursor: pyodbc.Cursor) -> list[tuple[int, int]]:
    cursor.execute(
        """
        SELECT  team_id,
                COUNT(*) AS team_count
        FROM    dimension.team_dim
        GROUP BY team_id
        HAVING  COUNT(*) > 1;
        """
    )
    return [(int(row.team_id), int(row.team_count)) for row in cursor.fetchall()]


def mark_batch_failed(cursor: pyodbc.Cursor, load_batch_id: str, error_message: str) -> None:
    cursor.execute(
        """
        EXEC audit.P_END_LOAD_BATCH
            @Load_batch_id = ?,
            @Status = 'Failed',
            @RowsInserted = 0,
            @RowsUpdated = 0,
            @ErrorMessage = ?;
        """,
        load_batch_id,
        error_message[:4000],
    )


def run(endpoint: str) -> int:
    raw_teams = fetch_teams(endpoint)
    parsed_teams = [parse_team(team) for team in raw_teams]

    load_batch_id: str | None = None
    connection = pyodbc.connect(build_connection_string())

    try:
        cursor = connection.cursor()
        team_count_before = get_team_count(cursor)
        load_batch_id = start_load_batch(cursor)
        insert_count = insert_staging_rows(cursor, load_batch_id, parsed_teams)
        connection.commit()

        execute_dimension_load(cursor, load_batch_id)
        connection.commit()

        team_count_after = get_team_count(cursor)
        duplicate_teams = get_duplicate_teams(cursor)

        print(f"Load batch: {load_batch_id}")
        print(f"API teams parsed: {len(parsed_teams)}")
        print(f"Staging rows inserted: {insert_count}")
        print(f"Team dimension count before: {team_count_before}")
        print(f"Team dimension count after: {team_count_after}")
        print(f"Duplicate team check rows: {len(duplicate_teams)}")

        if duplicate_teams:
            for team_id, team_count in duplicate_teams:
                print(f"Duplicate team_id {team_id}: {team_count} rows")
            return 1

        return 0
    except Exception as exc:
        connection.rollback()
        if load_batch_id is not None:
            mark_batch_failed(connection.cursor(), load_batch_id, str(exc))
            connection.commit()
        raise
    finally:
        connection.close()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Load NHL teams into the warehouse.")
    parser.add_argument(
        "--endpoint",
        default=os.getenv("NHL_TEAMS_ENDPOINT", DEFAULT_TEAMS_ENDPOINT),
        help="NHL team endpoint URL.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    try:
        sys.exit(run(args.endpoint))
    except Exception as error:
        print(f"Team ETL failed: {error}", file=sys.stderr)
        sys.exit(1)
