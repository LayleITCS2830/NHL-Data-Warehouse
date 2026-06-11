"""Shared helpers for NHL data warehouse Python ETL scripts."""

from __future__ import annotations

from datetime import date, datetime, timedelta
import os
from typing import Any, Iterable

import pyodbc
import requests


SOURCE_SYSTEM = "NHL API"

# Default API endpoints used when environment variables do not override them.
DEFAULT_TEAMS_ENDPOINT = "https://api.nhle.com/stats/rest/en/team"
DEFAULT_SCHEDULE_ENDPOINT_TEMPLATE = "https://api-web.nhle.com/v1/schedule/{game_date}"
DEFAULT_ROSTER_ENDPOINT_TEMPLATE = "https://api-web.nhle.com/v1/roster/{team_abbrev}/current"
DEFAULT_BOXSCORE_ENDPOINT_TEMPLATE = "https://api-web.nhle.com/v1/gamecenter/{game_id}/boxscore"

# Staging tables that ETL scripts are allowed to truncate.
STAGING_TABLES = {
    "staging.team_raw",
    "staging.player_raw",
    "staging.game_raw",
    "staging.player_game_stats_raw",
}


def build_connection_string() -> str:
    # Prefer a full connection string when supplied by the caller or scheduler.
    connection_string = os.getenv("NHL_DW_CONNECTION_STRING")
    if connection_string:
        return connection_string

    # Otherwise build a trusted SQL Server connection from individual settings.
    server = os.getenv("NHL_DW_SQL_SERVER", "localhost")
    database = os.getenv("NHL_DW_DATABASE", "NHLDataWarehouse")
    driver = os.getenv("NHL_DW_ODBC_DRIVER", "ODBC Driver 17 for SQL Server")
    trusted_connection = os.getenv("NHL_DW_TRUSTED_CONNECTION", "yes")
    trust_server_certificate = os.getenv("NHL_DW_TRUST_SERVER_CERTIFICATE", "yes")

    return (
        f"DRIVER={{{driver}}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"Trusted_Connection={trusted_connection};"
        f"TrustServerCertificate={trust_server_certificate};"
    )


def fetch_json(url: str) -> dict[str, Any]:
    # Fetch one NHL API response and fail fast for bad HTTP statuses.
    response = requests.get(url, timeout=30)
    response.raise_for_status()
    payload = response.json()

    # All current ETL callers expect a JSON object at the top level.
    if not isinstance(payload, dict):
        raise ValueError(f"Endpoint did not return a JSON object: {url}")

    return payload


def localized_text(value: Any) -> str | None:
    # NHL API name fields may be localized dictionaries or direct scalar values.
    if isinstance(value, dict):
        default_value = value.get("default")
        return str(default_value) if default_value is not None else None
    if value is None:
        return None
    return str(value)


def to_int(value: Any) -> int | None:
    # Treat missing and empty source values as SQL NULL.
    if value is None or value == "":
        return None
    return int(value)


def to_date(value: str | None) -> date | None:
    # NHL dates may arrive as date-only or datetime strings; only the date is staged.
    if not value:
        return None
    return datetime.strptime(value[:10], "%Y-%m-%d").date()


def parse_date(value: str) -> date:
    return datetime.strptime(value, "%Y-%m-%d").date()


def date_range(start_date: date, end_date: date) -> Iterable[date]:
    # Yield an inclusive date range for schedule endpoint calls.
    current_date = start_date
    while current_date <= end_date:
        yield current_date
        current_date += timedelta(days=1)


def toi_to_seconds(value: Any) -> int | None:
    # Convert NHL time-on-ice strings from MM:SS into an additive seconds measure.
    if not value:
        return None

    parts = str(value).split(":")
    if len(parts) != 2:
        return None

    return (int(parts[0]) * 60) + int(parts[1])


def start_load_batch(cursor: pyodbc.Cursor) -> str:
    # Start audit tracking and return the batch id used by staging rows.
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


def mark_batch_failed(cursor: pyodbc.Cursor, load_batch_id: str, error_message: str) -> None:
    # Keep audit failure messages inside the stored procedure parameter size.
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


def truncate_staging_table(cursor: pyodbc.Cursor, table_name: str) -> None:
    # Guard against accidental truncation of non-staging or unsupported tables.
    if table_name.lower() not in STAGING_TABLES:
        raise ValueError(f"Unsupported staging table for truncate: {table_name}")

    cursor.execute(f"TRUNCATE TABLE {table_name};")


def fetch_team_reference(endpoint: str) -> list[dict[str, Any]]:
    # Build a lightweight team lookup for roster and player loading.
    payload = fetch_json(endpoint)
    teams = payload.get("data")
    if not isinstance(teams, list):
        raise ValueError("NHL team endpoint response did not include a data list.")

    team_rows: list[dict[str, Any]] = []
    for team in teams:
        # Skip malformed records instead of blocking the whole reference list.
        if not isinstance(team, dict):
            continue

        team_id = team.get("id")
        team_abbrev = team.get("triCode") or team.get("rawTricode")
        if team_id is None or team_abbrev is None:
            continue

        team_rows.append({"team_id": int(team_id), "team_abbrev": str(team_abbrev)})

    return team_rows


def count_rows(cursor: pyodbc.Cursor, table_name: str) -> int:
    # Used by loaders to report before/after warehouse row counts.
    cursor.execute(f"SELECT COUNT(*) AS row_count FROM {table_name};")
    return int(cursor.fetchone().row_count)
