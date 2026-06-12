# NHL Data Warehouse

The NHL Data Warehouse is a SQL Server 2022 portfolio project that demonstrates professional data warehousing, ETL architecture, dimensional modeling, auditing, and reporting practices using publicly available NHL hockey data.

The project combines a SQL Server dimensional warehouse with Python and C# NHL API ingestion options. It is intended to show enterprise-style development patterns: layered schemas, rerunnable load procedures, source-to-staging extraction, audit logging, validation checks, SQLCMD deployment, and reporting views built for analytics consumers.

## Project Guides

- [Database README](Database/README.md): database architecture, schemas, object inventory, naming standards, deployment order, and warehouse load flow.
- [ETL README](ETL/README.md): Python and C# setup, source extraction commands, stored procedure replay, validation, and rerun expectations.

## Technology Stack

| Technology | Purpose |
| ---------- | ------- |
| SQL Server 2022 | Data warehouse platform |
| T-SQL | Tables, views, stored procedures, constraints, and load logic |
| SQLCMD | Database deployment script orchestration |
| Python | NHL API extraction, staging loads, and ETL orchestration |
| C# / .NET | Alternate NHL API extraction, staging loads, and ETL orchestration |
| pyodbc | Python-to-SQL Server connectivity |
| Microsoft.Data.SqlClient | C#-to-SQL Server connectivity |
| GitHub | Source control and portfolio presentation |

## Architecture

```text
NHL API
    |
    v
Python or C# ETL
    |
    v
staging tables
    |
    v
dimension and fact load procedures
    |
    v
reporting views
    |
    v
analytics / Power BI
```

## Repository Layout

```text
NHLDataWarehouse/
|-- Database/
|   |-- README.md
|   |-- 001_CreateDatabase.sql
|   |-- 002_CreateSchemas.sql
|   |-- 003_DeployDatabase.sql
|   |-- 004_LoadSampleData.sql
|   |-- Objects/
|   |   |-- Stored Procedures/
|   |   |-- Tables/
|   |   `-- Views/
|   |-- PreDeploymentScripts/
|   |-- PostDeploymentScripts/
|   `-- SampleData/
|-- ETL/
|   |-- README.md
|   |-- CSharp/
|   |   |-- README.md
|   |   |-- config.example.env
|   |   |-- NHLDataWarehouse.Etl.csproj
|   |   `-- Program.cs
|   |-- Python/
|   |   |-- config.example.env
|   |   |-- load_games.py
|   |   |-- load_players.py
|   |   |-- load_player_game_stats.py
|   |   |-- load_teams.py
|   |   |-- nhl_dw_etl.py
|   |   |-- requirements.txt
|   |   |-- run_all_etl.py
|   |   `-- run_load_procedures.py
|   `-- SSIS/
|-- DatabaseUnitTests/
|-- Documentation/
|-- agents.md
`-- README.md
```

## Database Layer

The database uses separate schemas for each warehouse responsibility:

- `staging`: raw NHL API landing tables.
- `dimension`: descriptive entities such as teams, players, and dates.
- `fact`: measurable game and player-game events.
- `audit`: ETL execution and load-batch tracking.
- `reporting`: business-friendly views for analytics and reporting.

Core warehouse objects include:

- Tables such as `dimension.TEAM_DIM`, `dimension.PLAYER_DIM`, `fact.GAME_FACT`, `fact.PLAYER_GAME_STATS_FACT`, and `audit.LOAD_BATCH`.
- Stored procedures such as `audit.P_START_LOAD_BATCH`, `dimension.P_LOAD_DIM_TEAM`, `fact.P_LOAD_FACT_GAME`, and `fact.P_LOAD_FACT_PLAYER_GAME_STATS`.
- Reporting views such as `reporting.V_TEAM_GAME_RESULTS`, `reporting.V_PLAYER_GAME_STATS`, `reporting.V_TEAM_SEASON_SUMMARY`, and `reporting.V_PLAYER_SEASON_SUMMARY`.

See [Database/README.md](Database/README.md) for object details, naming standards, deployment instructions, and the warehouse load sequence.

## ETL Layer

The ETL layer offers both Python and C# loaders. Both options load NHL API data into staging tables, execute matching warehouse load procedures, and validate duplicate-prevention expectations.

Primary Python ETL scripts:

- `load_teams.py`: loads NHL team data into `staging.TEAM_RAW` and `dimension.TEAM_DIM`.
- `load_players.py`: loads roster/player data into `staging.PLAYER_RAW` and `dimension.PLAYER_DIM`.
- `load_games.py`: loads schedule/game data into `staging.GAME_RAW` and `fact.GAME_FACT`.
- `load_player_game_stats.py`: loads boxscore player stats into `staging.PLAYER_GAME_STATS_RAW` and `fact.PLAYER_GAME_STATS_FACT`.
- `run_all_etl.py`: runs the source ETL scripts in dependency order.
- `run_load_procedures.py`: replays warehouse load procedures from the latest staging batches.

The C# ETL lives in `ETL/CSharp` and exposes matching commands through `dotnet run -- all`, `teams`, `players`, `games`, `player-stats`, and `replay-procedures`.

See [ETL/README.md](ETL/README.md) for setup, environment variables, filters, run commands, validation behavior, and rerun expectations.

## Quick Start

### 1. Deploy the Database

Open `Database/003_DeployDatabase.sql` in SQL Server Management Studio, enable SQLCMD mode, and execute it.

```text
Database/003_DeployDatabase.sql
```

Optional sample data can be loaded with:

```text
Database/004_LoadSampleData.sql
```

### 2. Configure ETL

Install Python dependencies:

```powershell
cd ETL\Python
python -m pip install -r requirements.txt
```

Set SQL Server connection environment variables or provide `NHL_DW_CONNECTION_STRING`. See [ETL/README.md](ETL/README.md) and `ETL/Python/config.example.env` for the full configuration options.

For C#, install the .NET 8 SDK and restore packages:

```powershell
cd ETL\CSharp
dotnet restore
```

### 3. Run the ETL

Run all source ETL steps in dependency order with Python:

```powershell
cd ETL\Python
python run_all_etl.py
```

Or run the C# ETL:

```powershell
cd ETL\CSharp
dotnet run -- all
```

Common filters are documented in [ETL/README.md](ETL/README.md), including team abbreviation filters, date ranges, stats date ranges, and explicit game ids.

## Development Standards

- Use schema-qualified database object names.
- Keep table and column definitions in uppercase Kimball-style naming.
- Use lowercase Kimball-style references inside stored procedures, views, functions, and ETL mappings.
- Keep stored procedure names in the `schema.P_[OPERATION]_[OBJECT]` pattern.
- Use `reporting.V_[VIEW_NAME]` for reporting views.
- Avoid `SELECT *`; explicitly list columns.
- Use `TRY/CATCH`, transactions, and audit logging for warehouse loads.
- Keep deployment scripts ordered by dependency.

Detailed database standards are maintained in [Database/README.md](Database/README.md) and [agents.md](agents.md).

## Current Capabilities

- SQL Server 2022 data warehouse deployment through SQLCMD scripts.
- Audit, staging, dimension, fact, and reporting schemas.
- Rerunnable dimension and fact load procedures.
- Python extraction from NHL API endpoints.
- C# extraction from NHL API endpoints.
- Batch-driven staging loads with raw JSON retention.
- Duplicate validation after ETL loads.
- Reporting views for team game results, player game stats, team season summaries, and player season summaries.

## Future Enhancements

- Expanded historical season loading.
- Additional schedule, standings, roster, and goalie statistics facts.
- Power BI dashboards over reporting views.
- SSIS package version of the ETL process.
- Automated database tests and CI/CD deployment pipelines.
- Broader data quality monitoring.

## Author

Andrew Layle

This project serves as a practical demonstration of enterprise-style database design, ETL development, dimensional modeling, and analytics engineering principles.
