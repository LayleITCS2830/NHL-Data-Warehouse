# NHL Data Warehouse - AGENTS.md

## Project Overview

This repository contains a SQL Server 2022 data warehouse for NHL analytics.

The project demonstrates professional data warehouse design, ETL architecture, dimensional modeling, auditing, and reporting using enterprise development practices.

## Project Guides

- Use `README.md` for the project-level overview and quick start.
- Use `Database/README.md` for database architecture, object inventory, deployment, and warehouse load flow.
- Use `ETL/README.md` for Python ETL setup, commands, filters, validation, and rerun expectations.

When updating documentation, keep the root README high level and put detailed subsystem instructions in the matching subfolder README.

## Technology Standards

- SQL Server 2022
- Compatibility level 160
- T-SQL for database development
- SQLCMD deployment scripts
- Python ETL for NHL API ingestion
- GitHub for source control

## Project Structure

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
|-- README.md
`-- agents.md
```

## Architecture

### Schemas

- `staging`
- `dimension`
- `fact`
- `reporting`
- `audit`

### Data Flow

```text
NHL API
    |
    v
Python ETL
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

## Database Naming Conventions

### Tables

Table definition scripts use uppercase Kimball-style table and column names.

Naming patterns:

- `dimension.TEAM_DIM`
- `dimension.PLAYER_DIM`
- `dimension.DATE_DIM`
- `fact.GAME_FACT`
- `fact.PLAYER_GAME_STATS_FACT`
- `staging.TEAM_RAW`
- `audit.LOAD_BATCH`

Column examples:

```sql
TEAM_KEY
TEAM_ID
TEAM_NAME
PLAYER_KEY
PLAYER_ID
PLAYER_FULL_NAME
GAME_DATE_KEY
LOAD_BATCH_ID
SOURCE_SYSTEM
CREATED_DATE
MODIFIED_DATE
IS_ACTIVE
```

### Stored Procedures

- Follow the pattern `schema.P_[OPERATION]_[OBJECT]`.
- Procedure names use uppercase after the schema name.
- Procedure parameters and local variables use lowercase snake_case.
- Table and column references inside stored procedures use lowercase Kimball-style names.
- Do not wrap the whole procedure body in an extra `BEGIN ... END` block after the header.
- Use `SET NOCOUNT ON` and `SET XACT_ABORT ON` immediately after the header comment.
- Prefer minimal semicolon use, but keep required semicolons such as before a CTE with `;WITH` and before `THROW` when following the current local pattern `;THROW`.
- Align `FROM`, `JOIN`, `WHERE`, `AND`, and `ON` clauses for readability.

Current examples:

```sql
audit.P_START_LOAD_BATCH
audit.P_END_LOAD_BATCH
dimension.P_LOAD_DIM_TEAM
dimension.P_LOAD_DIM_PLAYER
dimension.P_POPULATE_DATE_DIMENSION
fact.P_LOAD_FACT_GAME
fact.P_LOAD_FACT_PLAYER_GAME_STATS
```

Future procedure prefixes may use these operation categories when appropriate:

- `P_INTF_`: Interface/UI queries and screen data retrieval.
- `P_ETL_`: ETL operations.
- `P_EML_`: Email generation.
- `P_LOG_`: Logging operations.
- `P_SEC_`: Security operations.
- `P_REP_`: Reports.

### Views

- Reporting views use the pattern `reporting.V_[VIEW_NAME]`.
- View names use uppercase after the schema name.
- Table and column references inside views use lowercase Kimball-style names.
- Bracketed output aliases may use business-friendly title case.
- Use schema-qualified object references in `FROM` and `JOIN` clauses.
- Avoid `SELECT *`; explicitly list reporting columns.
- Use concise table aliases without `AS` in `FROM` and `JOIN` clauses.
- Prefer `JOIN` over `INNER JOIN` for inner joins.
- Align `SELECT`, `FROM`, `JOIN`, and `ON` clauses like `reporting.V_PLAYER_GAME_STATS`.

Current examples:

```sql
reporting.V_TEAM_SEASON_SUMMARY
reporting.V_PLAYER_GAME_STATS
reporting.V_TEAM_GAME_RESULTS
reporting.V_PLAYER_SEASON_SUMMARY
```

### Functions

- Functions use `schema.F_[FUNCTION_NAME]`.

Example:

```sql
dimension.F_GET_DATE_KEY
```

### Columns

- Column names in table definition scripts must be Kimball-style uppercase names.
- Column references inside stored procedures, views, functions, and ETL mappings must be Kimball-style lowercase names.
- Use underscores between words for readability.
- Surrogate keys use `[ENTITY]_KEY` in table definition scripts and `[entity]_key` in stored procedures, views, functions, and ETL mappings.
- Natural/source keys use `[ENTITY]_ID` in table definition scripts and `[entity]_id` in stored procedures, views, functions, and ETL mappings.
- Descriptive attributes use clear business names, such as `TEAM_NAME` / `team_name`, `PLAYER_FULL_NAME` / `player_full_name`, or `DIVISION_NAME` / `division_name`.
- Audit and metadata columns use names such as `LOAD_BATCH_ID`, `CREATED_DATE`, `MODIFIED_DATE`, `IS_ACTIVE`, and `SOURCE_SYSTEM` in table definition scripts.
- Do not create new camelCase or PascalCase table or column names.

### Constraints and Indexes

- Primary keys: `[TABLE_NAME]_pk`
- Foreign keys: `[PARENT_TABLE]_[CHILD_TABLE]_fk`, with numeric suffixes when needed
- Unique constraints: `[TABLE_NAME]_[COLUMN_NAME]_uq`
- Check constraints: `[TABLE_NAME]_[CONSTRAINT_NAME]_ck`
- Clustered indexes: `CX_[TABLE_NAME]__[COLUMN_NAME]`
- Nonclustered indexes: `IX_[TABLE_NAME]__[COLUMN_NAME]` or `IX_[TABLE_NAME]__[PURPOSE]`

Examples:

```sql
IX_GAME_FACT__GAME_ID
IX_PLAYER_DIM__PLAYER_ID
```

## Development Standards

- Use schema-qualified object names.
- Use meaningful object names and aliases.
- Use SQL Server 2022 syntax.
- Use `DATETIME2` for new date/time development unless a date-only type is clearly appropriate.
- Add useful comments to scripts, especially for deployment, non-obvious indexes, and complex load logic.
- Preserve natural keys from source systems.
- Use surrogate keys for dimension tables.
- Separate staging, warehouse, audit, and reporting objects by schema.
- Do not place warehouse objects in `dbo` unless explicitly required.
- Write rerunnable deployment scripts whenever practical.
- Ensure deployment scripts execute in dependency order.

## Code Templates

### View Template

```sql
USE NHLDataWarehouse
GO

CREATE OR ALTER VIEW reporting.V_VIEW_NAME
AS
SELECT  a.business_key AS [Business Key],
        a.descriptive_attribute AS [Descriptive Attribute],
        b.metric_value AS [Metric Value]
FROM    dimension.source_dim        a
JOIN    fact.source_fact            b   ON  b.source_key = a.source_key;
GO
```

### Stored Procedure Template

```sql
CREATE OR ALTER PROCEDURE [schema_name].[P_OPERATION_NAME]
    @parameter_1_name DATATYPE,
    @parameter_2_name DATATYPE = DEFAULT_VALUE,
    @output_parameter DATATYPE OUTPUT
AS
/*****************************************************************************************
PROC:   [schema_name].[P_OPERATION_NAME]
AUTHOR: YOUR_NAME
DATE:   MM/DD/YYYY

DESCRIPTION:
    A brief, clear description of what this procedure does.

NOTES:
    Any important assumptions, prerequisites, or side effects.

INPUT PARAMETERS:
    @parameter_1_name DATATYPE - Description of what this parameter represents.
    @parameter_2_name DATATYPE - Description. Default value: [specify default]

OUTPUT PARAMETERS:
    @output_parameter DATATYPE - Description of the value returned to the caller.

SAMPLE CALL:
    DECLARE @output_param DATATYPE
    EXEC [schema_name].[P_OPERATION_NAME]
        @parameter_1_name = 'value1',
        @parameter_2_name = 'value2',
        @output_parameter = @output_param OUTPUT
    SELECT @output_param AS result

CHANGE HISTORY:
    MM/DD/YYYY - AUTHOR - Initial creation

*****************************************************************************************/
SET NOCOUNT ON
SET XACT_ABORT ON

DECLARE @rows_inserted INT = 0,
        @rows_updated INT = 0,
        @rows_deleted INT = 0

BEGIN TRY
    BEGIN TRANSACTION

    -- Procedure logic goes here.

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE()

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    THROW
END CATCH

GO
```

### ETL Stored Procedure Template

```sql
CREATE OR ALTER PROCEDURE [schema_name].[P_LOAD_OBJECT]
    @load_batch_id UNIQUEIDENTIFIER
AS
/*****************************************************************************************
PROC:   [schema_name].[P_LOAD_OBJECT]
AUTHOR: YOUR_NAME
DATE:   MM/DD/YYYY

DESCRIPTION:
    Describe the source staging table, target warehouse table, and load operation.

NOTES:
    List required upstream staging tables or dimension loads.

INPUT PARAMETERS:
    @load_batch_id UNIQUEIDENTIFIER - The current load batch identifier.

SAMPLE CALL:
    DECLARE @load_batch_id UNIQUEIDENTIFIER = 'YOUR-BATCH-ID'
    EXEC [schema_name].[P_LOAD_OBJECT] @load_batch_id

CHANGE HISTORY:
    MM/DD/YYYY - AUTHOR - Initial creation

*****************************************************************************************/
SET NOCOUNT ON
SET XACT_ABORT ON

DECLARE @rows_inserted INT = 0,
        @rows_updated INT = 0

BEGIN TRY
    BEGIN TRANSACTION

    ;WITH source_rows AS
    (
        SELECT  src.natural_key,
                src.attribute_1,
                src.attribute_2
        FROM    staging.source_table    src
        WHERE   src.load_batch_id = @load_batch_id
        AND     src.natural_key IS NOT NULL
    )
    UPDATE  tgt
    SET     attribute_1 = src.attribute_1,
            attribute_2 = src.attribute_2,
            is_active = 1,
            modified_date = SYSUTCDATETIME()
    FROM    dimension.target_dim    tgt
    JOIN    source_rows             src ON  src.natural_key = tgt.natural_key
    WHERE   (   ISNULL(tgt.attribute_1, '') <> ISNULL(src.attribute_1, '')
            OR  ISNULL(tgt.attribute_2, '') <> ISNULL(src.attribute_2, '')
            OR  tgt.is_active <> 1
            )

    SET @rows_updated = @@ROWCOUNT

    ;WITH source_rows AS
    (
        SELECT  src.natural_key,
                src.attribute_1,
                src.attribute_2
        FROM    staging.source_table    src
        WHERE   src.load_batch_id = @load_batch_id
        AND     src.natural_key IS NOT NULL
    )
    INSERT INTO dimension.target_dim
            (natural_key, attribute_1, attribute_2)
    SELECT  src.natural_key,
            src.attribute_1,
            src.attribute_2
    FROM    source_rows     src
    WHERE   NOT EXISTS
            (
                SELECT  1
                FROM    dimension.target_dim    tgt
                WHERE   tgt.natural_key = src.natural_key
            )

    SET @rows_inserted = @@ROWCOUNT

    EXEC audit.P_END_LOAD_BATCH @load_batch_id, 'Succeeded', @rows_inserted, @rows_updated, NULL
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE()

    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    EXEC audit.P_END_LOAD_BATCH @load_batch_id, 'Failed', @rows_inserted, @rows_updated, @error_message
    ;THROW
END CATCH

GO
```

## ETL Standards

All ETL procedures and Python source loads must:

- Support reruns.
- Prevent duplicate records.
- Preserve natural/source keys from the NHL API.
- Log execution activity to `audit.LOAD_BATCH`.
- Use `TRY/CATCH` error handling in warehouse procedures.
- Use transactions where appropriate.
- Validate source data before loading warehouse tables.
- Run dimensions before facts when facts depend on dimension surrogate keys.

## Dimensional Modeling Standards

### Dimensions

- Use surrogate keys as primary keys.
- Preserve natural keys as alternate keys when appropriate.
- Store descriptive attributes in dimensions.
- Slowly Changing Dimension support may be added in future phases.

### Facts

- Store measurable business events.
- Reference dimensions through foreign keys.
- Avoid duplicate fact records.
- Keep facts additive whenever practical.

## Reporting Standards

- Reporting views should expose business-friendly column names.
- Hide implementation details from reporting consumers.
- Reporting queries should use reporting views rather than direct fact or dimension access.

## Git Standards

When creating or modifying database objects:

1. Create or update the object script.
2. Create or update supporting indexes when necessary.
3. Update documentation when architecture changes.
4. Keep commits focused and small.
5. Use meaningful commit messages.
6. Ensure deployment scripts execute in dependency order.

## Future Enhancements

- Historical season loading.
- Additional schedule, standings, roster, and goalie statistics facts.
- Power BI dashboards.
- SSIS packages.
- Automated testing.
- CI/CD deployment pipelines.
- Advanced analytics and reporting.
