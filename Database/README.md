# NHLDataWarehouse

NHLDataWarehouse is a SQL Server 2022 portfolio data warehouse for NHL analytics. It demonstrates separate staging, dimension, fact, audit, and reporting layers with repeatable deployment scripts.

## Architecture

- `Staging`: raw NHL API landing tables with batch metadata and optional JSON payloads.
- `Dimension`: conformed descriptive entities such as teams, players, and dates.
- `Fact`: game and player game statistic events keyed to dimensions.
- `Audit`: load batch tracking for ETL status, counts, and errors.
- `Reporting`: business-friendly views over warehouse tables.

## ETL Flow

1. Start a load with `Audit.usp_StartLoadBatch`.
2. Insert raw API rows into `Staging.*Raw` tables using the returned `LoadBatchID`.
3. Load dimensions with `Dimension.usp_LoadDimTeam` and `Dimension.usp_LoadDimPlayer`.
4. Populate required dates with `Dimension.usp_PopulateDateDimension`.
5. Load facts with `Fact.usp_LoadFactGame` and `Fact.usp_LoadFactPlayerGameStats`.
6. Finish status is recorded through `Audit.usp_EndLoadBatch`.

## Tables

- `Audit.LoadBatch`
- `Dimension.Date`
- `Dimension.Player`
- `Dimension.Team`
- `Fact.Game`
- `Fact.PlayerGameStats`
- `Staging.GameRaw`
- `Staging.PlayerGameStatsRaw`
- `Staging.PlayerRaw`
- `Staging.TeamRaw`

## Stored Procedures

- `Audit.usp_StartLoadBatch`
- `Audit.usp_EndLoadBatch`
- `Dimension.usp_LoadDimTeam`
- `Dimension.usp_LoadDimPlayer`
- `Dimension.usp_PopulateDateDimension`
- `Fact.usp_LoadFactGame`
- `Fact.usp_LoadFactPlayerGameStats`

## Reporting Views

- `Reporting.vwTeamGameResults`
- `Reporting.vwPlayerGameStats`
- `Reporting.vwTeamSeasonSummary`
- `Reporting.vwPlayerSeasonSummary`

## Run Order

Run these scripts in SQL Server Management Studio or Azure Data Studio, or execute `003_DeployDatabase.sql` in SQLCMD mode from the `Database` folder:

1. `Database/003_DeployDatabase.sql`
2. optional: `Database/SampleData/001_InsertSampleData.sql`

The scripts avoid local file paths and can be rerun safely where practical.

## Future Enhancements

- Python extraction from the NHL API into staging tables.
- Power BI dashboard over reporting views.
- SSIS package version of the ETL process.
- Expanded schedule, standings, roster, and goalie statistics facts.
