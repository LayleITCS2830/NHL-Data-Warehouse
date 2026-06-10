# NHLDataWarehouse Database

NHLDataWarehouse is a SQL Server 2022 data warehouse for NHL analytics. The database layer demonstrates separate staging, dimension, fact, audit, and reporting schemas with SQLCMD deployment scripts and rerunnable ETL patterns.

## Technology Standards

- SQL Server 2022
- Compatibility level 160
- T-SQL database development
- SQLCMD deployment scripts
- Schema-qualified object references

## Architecture

- `staging`: raw NHL API landing tables with batch metadata and optional JSON payloads.
- `dimension`: conformed descriptive entities such as teams, players, and dates.
- `fact`: game and player game statistic events keyed to dimensions.
- `audit`: load batch tracking for ETL status, counts, and errors.
- `reporting`: business-friendly views over warehouse tables.

## Data Flow

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

## Naming Standards

### Tables

Tables use `[schema].[TABLE_DIM]`, `[schema].[TABLE_FACT]`, `[schema].[TABLE_RAW]`, or other descriptive uppercase names.

```sql
dimension.TEAM_DIM
dimension.PLAYER_DIM
dimension.DATE_DIM
fact.GAME_FACT
fact.PLAYER_GAME_STATS_FACT
staging.TEAM_RAW
audit.LOAD_BATCH
```

### Stored Procedures

Stored procedures use `[schema].P_[OPERATION]__[OBJECT]`.

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

Reporting views use business-friendly `vw_` names.

```sql
reporting.vw_team_game_results
reporting.vw_player_game_stats
reporting.vw_team_season_summary
reporting.vw_player_season_summary
```

### Constraints and Indexes

- Primary keys: `[TABLE_NAME]_pk`
- Foreign keys: `[PARENT_TABLE]_[CHILD_TABLE]_fk`, with numeric suffixes when needed
- Unique constraints: `[TABLE_NAME]_[COLUMN_NAME]_uq`
- Check constraints: `[TABLE_NAME]_[CONSTRAINT_NAME]_ck`
- Clustered indexes: `CX_[TABLE_NAME]__[COLUMN_NAME]`
- Nonclustered indexes: `IX_[TABLE_NAME]__[COLUMN_NAME]` or `IX_[TABLE_NAME]__[PURPOSE]`

## ETL Flow

1. Start a load with `audit.P_START_LOAD_BATCH`.
2. Insert raw API rows into `staging.*_RAW` tables using the returned `LoadBatchID`.
3. Populate required dates with `dimension.P_POPULATE_DATE_DIMENSION`.
4. Load dimensions with `dimension.P_LOAD_DIM_TEAM` and `dimension.P_LOAD_DIM_PLAYER`.
5. Load facts with `fact.P_LOAD_FACT_GAME` and `fact.P_LOAD_FACT_PLAYER_GAME_STATS`.
6. Finish status is recorded through `audit.P_END_LOAD_BATCH`.

## Code Standards

- Use `SET NOCOUNT ON` in stored procedures.
- Avoid `SELECT *`.
- Explicitly list columns in `INSERT` statements.
- Use `TRY/CATCH` error handling.
- Use transactions when modifying warehouse data.
- Write rerunnable deployment scripts where practical.
- Use schema-qualified object references.
- Use meaningful aliases.

## ETL Standards

All ETL procedures must:

- Support reruns.
- Prevent duplicate records.
- Log execution activity to `audit.LOAD_BATCH`.
- Use `TRY/CATCH` error handling.
- Use transactions where appropriate.
- Validate source data before loading warehouse tables.

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

- `reporting.vw_team_game_results`
- `reporting.vw_player_game_stats`
- `reporting.vw_team_season_summary`
- `reporting.vw_player_season_summary`

## Run Order

Run `003_DeployDatabase.sql` in SQLCMD mode from the `Database` folder:

```text
Database/003_DeployDatabase.sql
```

To load sample data through the ETL procedures, run:

```text
Database/004_LoadSampleData.sql
```

The sample data runner cleans prior sample rows, stages sample data, and executes the load procedures in dependency order.

## Future Enhancements

- Python extraction from the NHL API into staging tables.
- Power BI dashboard over reporting views.
- SSIS package version of the ETL process.
- Expanded schedule, standings, roster, and goalie statistics facts.
