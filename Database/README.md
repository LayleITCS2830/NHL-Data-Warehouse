# NHLDataWarehouse Database

This folder contains the SQL Server 2022 database layer for the NHL Data Warehouse. It includes database and schema creation scripts, warehouse object scripts, reporting views, and sample-data deployment support.

The database is organized around a traditional analytics flow:

```text
NHL API
    |
    v
staging
    |
    v
dimension / fact
    |
    v
reporting views
```

## Technology Standards

- SQL Server 2022
- Compatibility level 160
- T-SQL database development
- SQLCMD deployment scripts
- Schema-qualified object references
- Rerunnable object scripts where practical

## Folder Layout

```text
Database/
|-- 001_CreateDatabase.sql
|-- 002_CreateSchemas.sql
|-- 003_DeployDatabase.sql
|-- 004_LoadSampleData.sql
|-- Objects/
|   |-- Stored Procedures/
|   |-- Tables/
|   `-- Views/
|-- PreDeploymentScripts/
|-- PostDeploymentScripts/
|-- SampleData/
`-- README.md
```

## Schemas

- `staging`: raw NHL API landing tables with batch metadata and optional JSON payloads.
- `dimension`: conformed descriptive entities such as teams, players, and dates.
- `fact`: game and player game statistic events keyed to dimensions.
- `audit`: load batch tracking for ETL status, counts, and errors.
- `reporting`: business-friendly views over warehouse tables.

## Database Objects

### Tables

- `audit.LOAD_BATCH`
- `dimension.DATE_DIM`
- `dimension.PLAYER_DIM`
- `dimension.TEAM_DIM`
- `fact.GAME_FACT`
- `fact.PLAYER_GAME_STATS_FACT`
- `staging.GAME_RAW`
- `staging.PLAYER_GAME_STATS_RAW`
- `staging.PLAYER_RAW`
- `staging.TEAM_RAW`

### Stored Procedures

- `audit.P_START_LOAD_BATCH`
- `audit.P_END_LOAD_BATCH`
- `dimension.P_LOAD_DIM_TEAM`
- `dimension.P_LOAD_DIM_PLAYER`
- `dimension.P_POPULATE_DATE_DIMENSION`
- `fact.P_LOAD_FACT_GAME`
- `fact.P_LOAD_FACT_PLAYER_GAME_STATS`

### Reporting Views

- `reporting.V_TEAM_GAME_RESULTS`
- `reporting.V_PLAYER_GAME_STATS`
- `reporting.V_TEAM_SEASON_SUMMARY`
- `reporting.V_PLAYER_SEASON_SUMMARY`

## Naming Standards

### Tables

Tables use uppercase Kimball-style names under their target schema.

```sql
dimension.TEAM_DIM
dimension.PLAYER_DIM
dimension.DATE_DIM
fact.GAME_FACT
fact.PLAYER_GAME_STATS_FACT
staging.TEAM_RAW
audit.LOAD_BATCH
```

Table definition scripts use uppercase column names such as `TEAM_KEY`, `TEAM_ID`, `LOAD_BATCH_ID`, and `CREATED_DATE`.

### Stored Procedures

Stored procedures use `schema.P_[OPERATION]_[OBJECT]`. Procedure names are uppercase after the schema name, and parameters and local variables use lowercase snake_case.

```sql
audit.P_START_LOAD_BATCH
audit.P_END_LOAD_BATCH
dimension.P_LOAD_DIM_TEAM
dimension.P_LOAD_DIM_PLAYER
dimension.P_POPULATE_DATE_DIMENSION
fact.P_LOAD_FACT_GAME
fact.P_LOAD_FACT_PLAYER_GAME_STATS
```

### Views

Reporting views use `reporting.V_[VIEW_NAME]`. View definitions explicitly list reporting columns and expose business-friendly bracketed aliases.

```sql
reporting.V_TEAM_GAME_RESULTS
reporting.V_PLAYER_GAME_STATS
reporting.V_TEAM_SEASON_SUMMARY
reporting.V_PLAYER_SEASON_SUMMARY
```

### Constraints and Indexes

- Primary keys: `[TABLE_NAME]_pk`
- Foreign keys: `[PARENT_TABLE]_[CHILD_TABLE]_fk`, with numeric suffixes when needed
- Unique constraints: `[TABLE_NAME]_[COLUMN_NAME]_uq`
- Check constraints: `[TABLE_NAME]_[CONSTRAINT_NAME]_ck`
- Clustered indexes: `CX_[TABLE_NAME]__[COLUMN_NAME]`
- Nonclustered indexes: `IX_[TABLE_NAME]__[COLUMN_NAME]` or `IX_[TABLE_NAME]__[PURPOSE]`

## Deployment

Run `003_DeployDatabase.sql` in SQLCMD mode from SQL Server Management Studio or another SQLCMD-compatible tool:

```text
Database/003_DeployDatabase.sql
```

The deployment script runs the database scripts in dependency order:

1. Create database and schemas.
2. Create audit, dimension, fact, and staging tables.
3. Create load and audit stored procedures.
4. Create reporting views.

To load the included sample data through the warehouse procedures, run:

```text
Database/004_LoadSampleData.sql
```

The sample data runner cleans prior sample rows, stages sample data, and executes load procedures in dependency order.

## Warehouse Load Flow

1. Start a load with `audit.P_START_LOAD_BATCH`.
2. Insert raw API rows into the appropriate `staging.*_RAW` table using the returned `load_batch_id`.
3. Populate required dates with `dimension.P_POPULATE_DATE_DIMENSION`.
4. Load dimensions with `dimension.P_LOAD_DIM_TEAM` and `dimension.P_LOAD_DIM_PLAYER`.
5. Load facts with `fact.P_LOAD_FACT_GAME` and `fact.P_LOAD_FACT_PLAYER_GAME_STATS`.
6. Record final status through `audit.P_END_LOAD_BATCH`.

## Code Standards

- Use schema-qualified object references.
- Use `SET NOCOUNT ON` and `SET XACT_ABORT ON` in stored procedures.
- Avoid `SELECT *`.
- Explicitly list columns in `INSERT` statements.
- Use `TRY/CATCH` error handling for ETL procedures and multi-step warehouse modifications.
- Use transactions for ETL procedures and multi-step warehouse modifications.
- Use lowercase Kimball-style table and column references in stored procedures, views, and functions.
- Keep reporting aliases business-friendly and bracketed.
- Write rerunnable deployment scripts where practical.

## ETL Expectations

All warehouse load procedures must:

- Support reruns.
- Prevent duplicate records.
- Preserve natural/source keys from the NHL API.
- Log execution activity to `audit.LOAD_BATCH`.
- Use `TRY/CATCH` error handling.
- Use transactions where appropriate.
- Validate source data before loading warehouse tables.

Python source extraction and orchestration live under `ETL/Python`. See `ETL/README.md` for setup, command-line options, and source-to-staging details.

## Future Enhancements

- Expanded historical season loading.
- Additional schedule, standings, roster, and goalie statistics facts.
- Power BI dashboards over reporting views.
- SSIS package version of the ETL process.
- Automated testing and CI/CD deployment pipelines.
