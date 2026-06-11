"""Execute warehouse load stored procedures in dependency order.

This script assumes the staging tables have already been populated. It derives
the date dimension range from staging.game_raw and uses the latest load_batch_id
from each staging table for the dimension and fact load procedures.
"""

from __future__ import annotations

import sys
from datetime import date

import pyodbc

from nhl_dw_etl import build_connection_string


LOAD_BATCH_TABLES = {
    "team": "staging.team_raw",
    "player": "staging.player_raw",
    "game": "staging.game_raw",
    "player_game_stats": "staging.player_game_stats_raw",
}


def get_game_date_range(cursor: pyodbc.Cursor) -> tuple[date, date]:
    cursor.execute(
        """
        SELECT  MIN(game_date) AS start_date,
                MAX(game_date) AS end_date
        FROM    staging.game_raw
        WHERE   game_date IS NOT NULL;
        """
    )
    row = cursor.fetchone()
    if row is None or row.start_date is None or row.end_date is None:
        raise RuntimeError("staging.game_raw does not contain game dates for DATE_DIM.")

    return row.start_date, row.end_date


def get_latest_load_batch_id(cursor: pyodbc.Cursor, table_name: str) -> str:
    if table_name not in LOAD_BATCH_TABLES.values():
        raise ValueError(f"Unsupported staging table: {table_name}")

    cursor.execute(
        f"""
        SELECT  TOP (1)
                CONVERT(VARCHAR(36), load_batch_id) AS load_batch_id
        FROM    {table_name}
        WHERE   load_batch_id IS NOT NULL
        GROUP BY load_batch_id
        ORDER BY MAX(created_date) DESC;
        """
    )
    row = cursor.fetchone()
    if row is None:
        raise RuntimeError(f"{table_name} does not contain a load_batch_id.")

    return row.load_batch_id


def execute_date_dimension_load(cursor: pyodbc.Cursor) -> tuple[date, date]:
    start_date, end_date = get_game_date_range(cursor)
    cursor.execute(
        """
        EXEC dimension.P_POPULATE_DATE_DIMENSION
            @StartDate = ?,
            @EndDate = ?;
        """,
        start_date,
        end_date,
    )
    return start_date, end_date


def execute_batch_load(
    cursor: pyodbc.Cursor, procedure_name: str, staging_table_name: str
) -> str:
    load_batch_id = get_latest_load_batch_id(cursor, staging_table_name)
    cursor.execute(f"EXEC {procedure_name} @load_batch_id = ?;", load_batch_id)
    return load_batch_id


def run() -> int:
    connection = pyodbc.connect(build_connection_string())

    try:
        cursor = connection.cursor()

        print("Executing dimension.P_POPULATE_DATE_DIMENSION")
        start_date, end_date = execute_date_dimension_load(cursor)
        connection.commit()
        print(f"DATE_DIM range loaded: {start_date} through {end_date}")

        load_steps = [
            ("dimension.P_LOAD_DIM_TEAM", LOAD_BATCH_TABLES["team"]),
            ("dimension.P_LOAD_DIM_PLAYER", LOAD_BATCH_TABLES["player"]),
            ("fact.P_LOAD_FACT_GAME", LOAD_BATCH_TABLES["game"]),
            (
                "fact.P_LOAD_FACT_PLAYER_GAME_STATS",
                LOAD_BATCH_TABLES["player_game_stats"],
            ),
        ]

        for procedure_name, staging_table_name in load_steps:
            print(f"Executing {procedure_name}")
            load_batch_id = execute_batch_load(cursor, procedure_name, staging_table_name)
            connection.commit()
            print(f"{procedure_name} completed for load batch {load_batch_id}")

        return 0
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


if __name__ == "__main__":
    try:
        sys.exit(run())
    except Exception as error:
        print(f"Stored procedure load failed: {error}", file=sys.stderr)
        sys.exit(1)
