"""Load NHL player records into the data warehouse.

This script stages current roster players in staging.player_raw, executes
dimension.P_LOAD_DIM_PLAYER, and validates that no duplicate source players exist
in dimension.player_dim. The staging table is truncated before each load.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from typing import Any

import pyodbc
import requests

from nhl_dw_etl import (
    DEFAULT_ROSTER_ENDPOINT_TEMPLATE,
    DEFAULT_TEAMS_ENDPOINT,
    SOURCE_SYSTEM,
    build_connection_string,
    count_rows,
    fetch_json,
    fetch_team_reference,
    localized_text,
    mark_batch_failed,
    start_load_batch,
    to_date,
    truncate_staging_table,
)


def parse_player(raw_player: dict[str, Any], team_id: int) -> dict[str, Any]:
    player_id = raw_player.get("id")
    first_name = localized_text(raw_player.get("firstName"))
    last_name = localized_text(raw_player.get("lastName"))

    if player_id is None or (first_name is None and last_name is None):
        raise ValueError(f"Player record is missing id or name: {raw_player}")

    full_name = " ".join(part for part in [first_name, last_name] if part)

    return {
        "raw_json": json.dumps(raw_player, ensure_ascii=False, sort_keys=True),
        "player_id": int(player_id),
        "team_id": team_id,
        "first_name": first_name,
        "last_name": last_name,
        "full_name": full_name,
        "position_code": raw_player.get("positionCode"),
        "shoots_catches": raw_player.get("shootsCatches"),
        "birth_date": to_date(raw_player.get("birthDate")),
    }


def fetch_players(
    teams_endpoint: str, roster_endpoint_template: str, team_abbrevs: set[str] | None
) -> list[dict[str, Any]]:
    players: list[dict[str, Any]] = []
    teams = fetch_team_reference(teams_endpoint)
    processed_team_abbrevs: set[str] = set()

    for team in teams:
        team_abbrev = team["team_abbrev"].upper()
        if team_abbrev in processed_team_abbrevs:
            continue
        processed_team_abbrevs.add(team_abbrev)

        if team_abbrevs is not None and team_abbrev not in team_abbrevs:
            continue

        roster_url = roster_endpoint_template.format(team_abbrev=team_abbrev)
        try:
            roster = fetch_json(roster_url)
        except requests.HTTPError as exc:
            if exc.response is not None and exc.response.status_code == 404:
                print(f"Roster not found for {team_abbrev}; skipping team.")
                continue
            raise

        for roster_group in ("forwards", "defensemen", "goalies"):
            raw_players = roster.get(roster_group, [])
            if not isinstance(raw_players, list):
                continue

            for raw_player in raw_players:
                if isinstance(raw_player, dict):
                    players.append(parse_player(raw_player, team["team_id"]))

    return players


def insert_staging_rows(
    cursor: pyodbc.Cursor, load_batch_id: str, players: list[dict[str, Any]]
) -> int:
    insert_sql = """
        INSERT INTO staging.player_raw
                (source_system,
                load_batch_id,
                raw_json,
                player_id,
                team_id,
                first_name,
                last_name,
                full_name,
                position_code,
                shoots_catches,
                birth_date)
        VALUES  (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    """

    rows = [
        (
            SOURCE_SYSTEM,
            load_batch_id,
            player["raw_json"],
            player["player_id"],
            player["team_id"],
            player["first_name"],
            player["last_name"],
            player["full_name"],
            player["position_code"],
            player["shoots_catches"],
            player["birth_date"],
        )
        for player in players
    ]

    if not rows:
        return 0

    cursor.fast_executemany = True
    cursor.executemany(insert_sql, rows)
    return len(rows)


def execute_dimension_load(cursor: pyodbc.Cursor, load_batch_id: str) -> None:
    cursor.execute("EXEC dimension.P_LOAD_DIM_PLAYER @load_batch_id = ?;", load_batch_id)


def get_duplicate_players(cursor: pyodbc.Cursor) -> list[tuple[int, int]]:
    cursor.execute(
        """
        SELECT  player_id,
                COUNT(*) AS player_count
        FROM    dimension.player_dim
        GROUP BY player_id
        HAVING  COUNT(*) > 1;
        """
    )
    return [(int(row.player_id), int(row.player_count)) for row in cursor.fetchall()]


def run(
    teams_endpoint: str, roster_endpoint_template: str, team_abbrevs: set[str] | None
) -> int:
    players = fetch_players(teams_endpoint, roster_endpoint_template, team_abbrevs)

    load_batch_id: str | None = None
    connection = pyodbc.connect(build_connection_string())

    try:
        cursor = connection.cursor()
        player_count_before = count_rows(cursor, "dimension.player_dim")
        load_batch_id = start_load_batch(cursor)
        truncate_staging_table(cursor, "staging.player_raw")
        insert_count = insert_staging_rows(cursor, load_batch_id, players)
        connection.commit()

        execute_dimension_load(cursor, load_batch_id)
        connection.commit()

        player_count_after = count_rows(cursor, "dimension.player_dim")
        duplicate_players = get_duplicate_players(cursor)

        print(f"Load batch: {load_batch_id}")
        print(f"API players parsed: {len(players)}")
        print(f"Staging rows inserted: {insert_count}")
        print(f"Player dimension count before: {player_count_before}")
        print(f"Player dimension count after: {player_count_after}")
        print(f"Duplicate player check rows: {len(duplicate_players)}")

        if duplicate_players:
            for player_id, player_count in duplicate_players:
                print(f"Duplicate player_id {player_id}: {player_count} rows")
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


def parse_team_abbrevs(value: str | None) -> set[str] | None:
    if not value:
        return None
    return {team_abbrev.strip().upper() for team_abbrev in value.split(",") if team_abbrev.strip()}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Load NHL players into the warehouse.")
    parser.add_argument(
        "--teams-endpoint",
        default=os.getenv("NHL_TEAMS_ENDPOINT", DEFAULT_TEAMS_ENDPOINT),
        help="NHL team reference endpoint URL.",
    )
    parser.add_argument(
        "--roster-endpoint-template",
        default=os.getenv("NHL_ROSTER_ENDPOINT_TEMPLATE", DEFAULT_ROSTER_ENDPOINT_TEMPLATE),
        help="NHL roster endpoint template with {team_abbrev}.",
    )
    parser.add_argument(
        "--team-abbrevs",
        default=os.getenv("NHL_TEAM_ABBREVS"),
        help="Optional comma-separated team abbreviations to load, such as TOR,BOS.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    try:
        sys.exit(
            run(
                args.teams_endpoint,
                args.roster_endpoint_template,
                parse_team_abbrevs(args.team_abbrevs),
            )
        )
    except Exception as error:
        print(f"Player ETL failed: {error}", file=sys.stderr)
        sys.exit(1)
