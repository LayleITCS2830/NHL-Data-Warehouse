# NHL Data Warehouse ETL

This folder contains ETL options that load NHL API data into the SQL Server data
warehouse. The Python and C# implementations both stage source rows first and
then execute the shared warehouse stored procedures.

The ETL follows this flow:

```text
NHL API
    -> staging tables
    -> dimension and fact stored procedures
    -> validation checks
```

## Folder Layout

```text
ETL/
|-- README.md
|-- CSharp/
|   |-- README.md
|   |-- config.example.env
|   |-- NHLDataWarehouse.Etl.csproj
|   `-- Program.cs
|-- Python/
|   |-- .env
|   |-- config.example.env
|   |-- load_games.py
|   |-- load_players.py
|   |-- load_player_game_stats.py
|   |-- load_teams.py
|   |-- nhl_dw_etl.py
|   |-- requirements.txt
|   |-- run_all_etl.py
|   `-- run_load_procedures.py
`-- SSIS/
```

`__pycache__` may be created locally when Python scripts are compiled or run.

## Python Setup

Install Python dependencies:

```powershell
cd ETL\Python
python -m pip install -r requirements.txt
```

Set connection values using environment variables, or provide a complete
`NHL_DW_CONNECTION_STRING`.

```powershell
$env:NHL_DW_SQL_SERVER = "localhost"
$env:NHL_DW_DATABASE = "NHLDataWarehouse"
$env:NHL_DW_ODBC_DRIVER = "ODBC Driver 18 for SQL Server"
$env:NHL_DW_TRUSTED_CONNECTION = "yes"
$env:NHL_DW_TRUST_SERVER_CERTIFICATE = "yes"
```

Optional NHL API settings are documented in `Python\config.example.env`.

## C# Setup

Install the .NET 8 SDK and restore packages:

```powershell
cd ETL\CSharp
dotnet restore
```

Set a complete SQL Server connection string, or use the individual environment
variables documented in `CSharp\config.example.env`.

```powershell
$env:NHL_DW_CONNECTION_STRING = "Server=localhost;Database=NHLDataWarehouse;Trusted_Connection=True;TrustServerCertificate=True;"
```

See `CSharp\README.md` for the full C# command reference.

## Python Master ETL

Run all Python ETL steps in dependency order:

```powershell
cd ETL\Python
python run_all_etl.py
```

Default order:

1. `load_teams.py`
2. `load_players.py`
3. `load_games.py`
4. `load_player_game_stats.py`

To replay warehouse load procedures from the latest staging batches after the
source ETL completes:

```powershell
python run_all_etl.py --include-load-procedures
```

Useful optional filters:

```powershell
python run_all_etl.py --team-abbrevs TOR,BOS
python run_all_etl.py --start-date 2024-10-04 --end-date 2024-10-10
python run_all_etl.py --stats-start-date 2024-10-04 --stats-end-date 2024-10-10
python run_all_etl.py --game-ids 2024020001,2024020002
```

## C# Master ETL

Run all C# ETL steps in dependency order:

```powershell
cd ETL\CSharp
dotnet run -- all
```

Useful C# commands:

```powershell
dotnet run -- teams
dotnet run -- players --team-abbrevs TOR,BOS
dotnet run -- games --start-date 2024-10-04 --end-date 2024-10-10
dotnet run -- player-stats --game-ids 2024020001,2024020002
dotnet run -- replay-procedures
dotnet run -- all --include-load-procedures
```

## Individual ETL Steps

### Team Dimension

Script:

```powershell
python load_teams.py
```

Flow:

1. Start a load batch with `audit.P_START_LOAD_BATCH`.
2. Call the NHL teams endpoint.
3. Parse team records from the API response.
4. Truncate and load `staging.TEAM_RAW`.
5. Execute `dimension.P_LOAD_DIM_TEAM`.
6. Validate that no duplicate `team_id` values exist in `dimension.TEAM_DIM`.

Staging columns populated:

```sql
SOURCE_SYSTEM,
LOAD_BATCH_ID,
RAW_JSON,
TEAM_ID,
TEAM_NAME,
TEAM_ABBREVIATION,
CONFERENCE,
DIVISION
```

### Player Dimension

Script:

```powershell
python load_players.py
```

Flow:

1. Start a load batch with `audit.P_START_LOAD_BATCH`.
2. Call the NHL team reference endpoint.
3. Call each current roster endpoint.
4. Parse player records from forwards, defensemen, and goalies.
5. Truncate and load `staging.PLAYER_RAW`.
6. Execute `dimension.P_LOAD_DIM_PLAYER`.
7. Validate that no duplicate `player_id` values exist in `dimension.PLAYER_DIM`.

Staging columns populated:

```sql
SOURCE_SYSTEM,
LOAD_BATCH_ID,
RAW_JSON,
PLAYER_ID,
TEAM_ID,
FIRST_NAME,
LAST_NAME,
FULL_NAME,
POSITION_CODE,
SHOOTS_CATCHES,
BIRTH_DATE
```

Optional filter:

```powershell
python load_players.py --team-abbrevs TOR,BOS
```

### Game Fact

Script:

```powershell
python load_games.py
```

Flow:

1. Start a load batch with `audit.P_START_LOAD_BATCH`.
2. Call the NHL schedule endpoint for each date in the requested range.
3. Parse schedule game records.
4. Truncate and load `staging.GAME_RAW`.
5. Execute `fact.P_LOAD_FACT_GAME`.
6. Validate that no duplicate `game_id` values exist in `fact.GAME_FACT`.

Staging columns populated:

```sql
SOURCE_SYSTEM,
LOAD_BATCH_ID,
RAW_JSON,
GAME_ID,
GAME_DATE,
SEASON,
GAME_TYPE,
HOME_TEAM_ID,
AWAY_TEAM_ID,
HOME_GOALS,
AWAY_GOALS,
HOME_SHOTS,
AWAY_SHOTS
```

Optional date range:

```powershell
python load_games.py --start-date 2024-10-04 --end-date 2024-10-10
```

### Player Game Stats Fact

Script:

```powershell
python load_player_game_stats.py
```

Flow:

1. Start a load batch with `audit.P_START_LOAD_BATCH`.
2. Get final game ids from the schedule endpoint, or use explicit game ids.
3. Call each game boxscore endpoint.
4. Parse player game stats for away and home teams.
5. Truncate and load `staging.PLAYER_GAME_STATS_RAW`.
6. Execute `fact.P_LOAD_FACT_PLAYER_GAME_STATS`.
7. Validate that no duplicate `game_key`, `player_key`, and `team_key` rows exist in
   `fact.PLAYER_GAME_STATS_FACT`.

Staging columns populated:

```sql
SOURCE_SYSTEM,
LOAD_BATCH_ID,
RAW_JSON,
GAME_ID,
PLAYER_ID,
TEAM_ID,
GOALS,
ASSISTS,
SHOTS,
HITS,
BLOCKS,
PENALTY_MINUTES,
TIME_ON_ICE_SECONDS
```

Optional filters:

```powershell
python load_player_game_stats.py --start-date 2024-10-04 --end-date 2024-10-10
python load_player_game_stats.py --game-ids 2024020001,2024020002
```

## Stored Procedure Replay

`run_load_procedures.py` and the C# `replay-procedures` command assume staging
tables have already been populated. They derive the date dimension range from
`staging.GAME_RAW`, find the latest `load_batch_id` in each staging table, and
execute warehouse procedures in dependency order.

Run it directly:

```powershell
python run_load_procedures.py
```

C#:

```powershell
cd ETL\CSharp
dotnet run -- replay-procedures
```

Procedure order:

1. `dimension.P_POPULATE_DATE_DIMENSION`
2. `dimension.P_LOAD_DIM_TEAM`
3. `dimension.P_LOAD_DIM_PLAYER`
4. `fact.P_LOAD_FACT_GAME`
5. `fact.P_LOAD_FACT_PLAYER_GAME_STATS`

## Shared Helper Modules

`nhl_dw_etl.py` contains common ETL helpers:

* SQL Server connection string construction.
* NHL API JSON fetches.
* date, integer, localized text, and time-on-ice parsing.
* load batch start and failed-batch logging.
* staging table truncation safeguards.
* common row-count helpers.

`CSharp\Program.cs` contains equivalent C# helpers for connection string
construction, API fetches, parsing, staging truncation, bulk copy, warehouse
procedure execution, and validation checks.

## Audit and Error Handling

Each source ETL script:

1. Starts a load batch with `audit.P_START_LOAD_BATCH`.
2. Writes all parsed API rows with the returned `load_batch_id`.
3. Calls the matching dimension or fact load procedure.
4. Commits successful staging and warehouse work.
5. Rolls back on failure.
6. Marks the load batch as `Failed` when an exception occurs before the warehouse
   procedure completes its own audit logging.

## Rerun and Validation Expectations

The ETL is intended to be rerunnable:

* Staging tables are truncated before each source load.
* Warehouse procedures use update/insert patterns and duplicate-prevention checks.
* Natural/source keys from the NHL API are preserved.
* Validation queries run after each load and return a nonzero exit code if duplicate
  business keys are found.

Successful output includes the load batch identifier, parsed API row counts, staging
insert counts, warehouse row counts before and after loading, and duplicate check
counts. Duplicate check counts should be `0`.
