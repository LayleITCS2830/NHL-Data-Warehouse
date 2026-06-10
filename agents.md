# NHL Data Warehouse - AGENTS.md

## Project Overview

This repository contains a SQL Server 2022 data warehouse for NHL analytics.

The purpose of this project is to demonstrate professional data warehouse design, ETL architecture, dimensional modeling, auditing, and reporting using enterprise development practices.

---

## Technology Standards

* SQL Server 2022
* Compatibility Level 160
* T-SQL for database development
* SQLCMD deployment scripts
* GitHub for source control

---

## Project Structure

```text
NHLDataWarehouse/
│
├── Database/
│   ├── 001_CreateDatabase.sql
│   ├── 002_CreateSchemas.sql
│   ├── 003_DeployDatabase.sql
│   ├── Objects/
│   │   ├── Tables/
│   │   ├── Views/
│   │   ├── Functions/
│   │   └── Stored Procedures/
│   │
│   ├── Security/
│   ├── PreDeploymentScripts/
│   ├── PostDeploymentScripts/
│   ├── SampleData/
│   └── Model/
│
├── ETL/
│   ├── Python/
│   └── SSIS/
│
├── DatabaseUnitTests/
│
├── Documentation/
│   ├── ERD/
│   ├── Architecture/
│   └── Screenshots/
│
├── README.md
└── AGENTS.md
```

---
## Database Naming Conventions

### Stored Procedures
* Follow pattern `schema.P_[OPERATION]_[OBJECT]`.
* Procedure names use uppercase after the schema name.
* Procedure parameters and local variables use lowercase snake_case.
* Table and column references inside stored procedures use lowercase Kimball-style names.
* Do not wrap the whole procedure body in an extra `BEGIN ... END` block after the header.
* Use `SET NOCOUNT ON` and `SET XACT_ABORT ON` immediately after the header comment.
* Omit semicolons except where required by T-SQL, such as before a CTE with `;WITH`.
* `P_INTF_` - Interface/UI queries (data retrieval for screens)
* `P_ETL_` - ETL operations
* `P_EML_` - Email generation
* `P_LOG_` - Logging operations
* `P_SEC_` - Security operations
* `P_REP_` - Reports

### Functions
* Functions use `F_...`.

### Views
* Reporting views use pattern `reporting.V_[VIEW_NAME]`.
* View names use uppercase after the schema name.
* Table and column references inside views use lowercase Kimball-style names.
* Bracketed output aliases may use business-friendly title case.
* Use schema-qualified object references in `FROM` and `JOIN` clauses.
* Avoid `SELECT *`; explicitly list reporting columns.
* Use concise table aliases without `AS` in `FROM` and `JOIN` clauses.
* Prefer `JOIN` over `INNER JOIN` for inner joins.
* Align `SELECT`, `FROM`, `JOIN`, and `ON` clauses like `reporting.V_PLAYER_GAME_STATS`.

### Columns
* Column names in table definition scripts must be Kimball-style uppercase names.
* Column references inside stored procedures, views, and functions must be Kimball-style lowercase names.
* Use underscores between words for readability.
* Surrogate keys use `[ENTITY]_KEY` in table definition scripts and `[entity]_key` in stored procedures, views, and functions.
* Natural/source keys use `[ENTITY]_ID` in table definition scripts and `[entity]_id` in stored procedures, views, and functions.
* Descriptive attributes use clear business names, such as `TEAM_NAME` / `team_name`, `PLAYER_FULL_NAME` / `player_full_name`, or `DIVISION_NAME` / `division_name`.
* Audit and metadata columns use names such as `LOAD_BATCH_ID`, `CREATED_DATE`, `MODIFIED_DATE`, `IS_ACTIVE`, and `SOURCE_SYSTEM` in table definition scripts.
* Do not create new camelCase or PascalCase table/column names.

### Constraints
* Primary key constraints use `[TABLE]_pk`.
* Foreign key constraints commonly use `[REFERENCED_TABLE]_[LOCAL_TABLE]_fk`, with numeric suffixes when needed.
* Nonclustered indexes use `IX_[TABLE]__[COLUMN_OR_PURPOSE]`.

## Architecture

### Schemas

* staging
* dimension
* fact
* reporting
* audit

### Data Flow

```text
NHL API
    ↓
Staging
    ↓
Dimension / Fact
    ↓
Reporting Views
```

---

## Development Standards

* Use schema-qualified object names.
* Use meaningful object names.
* Use SQL Server 2022 syntax.
* Use DATETIME2 for new development.
* Add comments to all scripts.
* Preserve natural keys from source systems.
* Use surrogate keys for dimension tables.
* Use Kimball-style uppercase table and column names when creating tables and columns.
* Use Kimball-style lowercase table and column names in stored procedures, views, functions, and ETL mappings.
* Separate staging, warehouse, audit, and reporting objects by schema.
* Do not place warehouse objects in dbo unless explicitly required.

---

### Tables

**Naming Pattern in table definition scripts:** `[schema].[TABLE_DIM]` or `[schema].[TABLE_FACT]`

```sql
dimension.TEAM_DIM
dimension.PLAYER_DIM
fact.GAME_FACT
fact.PLAYER_GAME_STATS_FACT
staging.TEAM_RAW
audit.LOAD_BATCH
dimension.DATE_DIM
```

### Views

**Naming Pattern:** `[schema].V_[VIEW_NAME]`

```sql
reporting.V_TEAM_SEASON_SUMMARY
reporting.V_PLAYER_GAME_STATS
reporting.V_TEAM_GAME_RESULTS
reporting.V_PLAYER_SEASON_SUMMARY
```

### Stored Procedures

**Naming Pattern:** `[schema].P_[OPERATION]_[OBJECT]`

```sql
dimension.P_LOAD_DIM_TEAM
dimension.P_LOAD_DIM_PLAYER
dimension.P_POPULATE_DATE_DIMENSION
fact.P_LOAD_FACT_GAME
fact.P_LOAD_FACT_PLAYER_GAME_STATS
audit.P_START_LOAD_BATCH
audit.P_END_LOAD_BATCH
```

### Functions

**Naming Pattern:** `[schema].F_[FUNCTION_NAME]`

```sql
dimension.F_GET_DATE_KEY
```

### Constraints

* Primary key constraints: `[TABLE_NAME]_pk`
* Foreign key constraints: `[PARENT_TABLE]_[CHILD_TABLE]_fk` (with numeric suffix if multiple)
* Unique constraints: `[TABLE_NAME]_[COLUMN_NAME]_uq`
* Check constraints: `[TABLE_NAME]_[CONSTRAINT_NAME]_ck`

### Indexes

* Clustered index: `CX_[TABLE_NAME]__[COLUMN_NAME]`
* Nonclustered index: `IX_[TABLE_NAME]__[COLUMN_NAME]` or `IX_[TABLE_NAME]__[PURPOSE]`

```sql
IX_GAME_FACT__GAME_ID
IX_PLAYER_DIM__PLAYER_ID
```

### Tables and Columns

**Table definition scripts:** Kimball-style uppercase names with underscores between words.

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

**Stored procedures, views, and functions:** reference table and column names in Kimball-style lowercase.

```sql
team_key
team_id
team_name
player_key
player_id
player_full_name
game_date_key
load_batch_id
source_system
created_date
modified_date
is_active
```



---

## Code Standards

* Use SET NOCOUNT ON in stored procedures.
* Avoid SELECT *.
* Explicitly list columns in INSERT statements.
* Use TRY/CATCH error handling for ETL/load procedures and multi-step data modifications.
* Use transactions for ETL/load procedures and multi-step warehouse modifications.
* Write rerunnable deployment scripts whenever practical.
* Use schema-qualified object references.
* Use meaningful aliases.
* In stored procedures, align `FROM`, `JOIN`, `WHERE`, `AND`, and `ON` clauses for readability.

---

## Code Templates

### View Template

Use this template as a starting point when creating reporting views:

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

**View Template Guidelines:**
* Use uppercase `V_...` view names after the schema name.
* Use lowercase Kimball-style table and column references.
* Keep reporting output aliases business-friendly using bracketed title case.
* Put the first selected column on the `SELECT` line, then align subsequent columns.
* Align table aliases and `ON` predicates in `FROM` and `JOIN` clauses.
* Use concise aliases without `AS` for table sources.

### Stored Procedure Template

Use this template as a starting point when creating new stored procedures:

```sql
CREATE OR ALTER PROCEDURE [schema_name].[P_OPERATION_NAME]
    @parameter_1_name DATATYPE,
    @parameter_2_name DATATYPE = DEFAULT_VALUE,
    @output_parameter DATATYPE OUTPUT
AS
/*****************************************************************************************
PROC:	[schema_name].[P_OPERATION_NAME]
AUTHOR:	YOUR_NAME
DATE:	MM/DD/YYYY

DESCRIPTION:
    A brief, clear description of what this procedure does. Explain the business purpose
    and the key operations performed (e.g., inserts, updates, deletes, joins).

NOTES: 
    Any important assumptions, prerequisites, or side effects. For example:
    - What source or staging tables must be populated first?
    - Are there dependencies on other procedures?
    - Are there any special configurations or settings required?

INPUT PARAMETERS:
    @parameter_1_name DATATYPE - Description of what this parameter represents and
                                how it is used in the procedure.
    @parameter_2_name DATATYPE - Description. Default value: [specify default]

OUTPUT PARAMETERS:
    @output_parameter DATATYPE - Description of the value(s) returned to the caller.

SAMPLE CALL:
    DECLARE @output_param DATATYPE
    EXEC [schema_name].[P_OPERATION_NAME]
        @parameter_1_name = 'value1',
        @parameter_2_name = 'value2',
        @output_parameter = @output_param OUTPUT
    SELECT @output_param AS result

CHANGE HISTORY:
    MM/DD/YYYY - AUTHOR - Initial creation
    MM/DD/YYYY - AUTHOR - Description of change

*****************************************************************************************/
SET NOCOUNT ON
SET XACT_ABORT ON

DECLARE @rows_inserted INT = 0,
        @rows_updated INT = 0,
        @rows_deleted INT = 0

BEGIN TRY
    BEGIN TRANSACTION

    -- ========================================================================
    -- Your procedure logic goes here
    -- ========================================================================

    -- If this is an ETL procedure, call the audit procedures at the end:
    -- EXEC audit.P_END_LOAD_BATCH @load_batch_id, 'Succeeded', @rows_inserted, @rows_updated, NULL

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE()

    -- Rollback transaction if it's still active
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    -- If this is an ETL procedure, log the error:
    -- EXEC audit.P_END_LOAD_BATCH @load_batch_id, 'Failed', @rows_inserted, @rows_updated, @error_message

    -- Re-throw the error for the caller to handle
    THROW
END CATCH

GO
```

**Template Guidelines:**
* Replace placeholders with actual values (keep [schema_name] lowercase, [P_OPERATION_NAME] uppercase)
* The header block documents purpose, parameters, and usage
* Always include CHANGE HISTORY for tracking modifications
* Use TRY/CATCH for error handling and transaction management
* For ETL procedures, integrate with audit.P_START_LOAD_BATCH and audit.P_END_LOAD_BATCH
* Use lowercase snake_case for parameter names (`@parameter_1_name`, `@load_batch_id`) and variable names (`@rows_inserted`)
* Declare row count variables for logging and auditing

### ETL Stored Procedure Template

Use this template for ETL procedures that perform dimension/fact loading with upsert operations:

```sql
CREATE OR ALTER PROCEDURE [schema_name].[P_LOAD_OBJECT]
    @load_batch_id UNIQUEIDENTIFIER
AS
/*****************************************************************************************
PROC:	[schema_name].[P_LOAD_OBJECT]
AUTHOR:	YOUR_NAME
DATE:	MM/DD/YYYY

DESCRIPTION:
    A brief, clear description of the ETL operation. Explain what source table is being
    loaded from, what target table is being loaded to, and what type of operation is
    performed (insert, update, upsert, etc.).

NOTES: 
    This procedure assumes that all source staging tables have been populated with the
    latest data for the given @load_batch_id. Include any dependencies on other procedures
    or tables that must be loaded first (e.g., "dimension.team_dim must be loaded before
    this procedure is called").

INPUT PARAMETERS:
    @load_batch_id UNIQUEIDENTIFIER - The identifier for the current load batch, used to
                                    filter source data and for auditing purposes.

SAMPLE CALL:
    DECLARE @load_batch_id UNIQUEIDENTIFIER = 'YOUR-BATCH-ID'
    EXEC [schema_name].[P_LOAD_OBJECT] @load_batch_id

CHANGE HISTORY:
    MM/DD/YYYY - AUTHOR - Initial creation
    MM/DD/YYYY - AUTHOR - Description of change

*****************************************************************************************/
SET NOCOUNT ON
SET XACT_ABORT ON

DECLARE @rows_inserted INT = 0,
        @rows_updated INT = 0

BEGIN TRY
    BEGIN TRANSACTION

    -- ========================================================================
    -- UPDATE: Existing records
    -- ========================================================================
    ;WITH source_rows AS
    (
        SELECT  src.natural_key,
                src.attribute_1,
                src.attribute_2
        FROM    staging.source_table    src
        WHERE   src.load_batch_id = @load_batch_id
        AND     src.natural_key IS NOT NULL
    )
    UPDATE tgt
    SET attribute_1 = src.attribute_1,
        attribute_2 = src.attribute_2,
        is_active = 1,
        modified_date = SYSUTCDATETIME()
    FROM    dimension.target_dim  tgt
    JOIN    source_rows           src ON  src.natural_key = tgt.natural_key
    WHERE   ( ISNULL(tgt.attribute_1, '') <> ISNULL(src.attribute_1, '')
            OR  ISNULL(tgt.attribute_2, '') <> ISNULL(src.attribute_2, '')
            OR  tgt.is_active <> 1
            )

    SET @rows_updated = @@ROWCOUNT

    -- ========================================================================
    -- INSERT: New records
    -- ========================================================================
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
    SELECT  src.natural_key, src.attribute_1, src.attribute_2
    FROM    source_rows AS src
    WHERE NOT EXISTS  (
                        SELECT 1
                        FROM dimension.target_dim AS tgt
                        WHERE tgt.natural_key = src.natural_key
                    )

    SET @rows_inserted = @@ROWCOUNT

    -- Log success and commit
    EXEC audit.P_END_LOAD_BATCH @load_batch_id, 'Succeeded', @rows_inserted, @rows_updated, NULL
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE()

    -- Rollback and log failure
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    EXEC audit.P_END_LOAD_BATCH @load_batch_id, 'Failed', @rows_inserted, @rows_updated, @error_message
    THROW
END CATCH

GO
```

**ETL Template Guidelines:**
* Use CTEs (WITH statements) to define source rows with filtering logic
* Separate UPDATE and INSERT operations into distinct sections
* Update both data attributes AND metadata columns (`is_active`, `modified_date`)
* Include change detection logic in WHERE clause to avoid unnecessary updates
* Use NOT EXISTS to prevent duplicate inserts
* Always call audit.P_END_LOAD_BATCH with appropriate status and row counts
* Use lowercase snake_case for parameter names (`@load_batch_id`) and variable names (`@rows_inserted`, `@rows_updated`)
* Use Kimball-style lowercase table and column names in stored procedures, views, functions, and ETL mappings
* Indent SQL keywords and table aliases for readability (FROM, WHERE, JOIN on separate lines)
* Rollback transaction and log errors in CATCH block

---

## Indexing Standards

* Every table must have a named primary key.
* Evaluate foreign key columns for indexing.
* Create indexes only when there is a clear query or join benefit.
* Choose clustered indexes intentionally.
* Document non-obvious indexes with comments.
* Use consistent naming: `_pk`, `_cx`, `_ix`, `_fk`, `_uq`, `_ck` suffixes

---

## ETL Standards

All ETL procedures must:

* Support reruns.
* Prevent duplicate records.
* Log execution activity to `audit.load_batch`.
* Use TRY/CATCH error handling.
* Use transactions where appropriate.
* Validate source data before loading warehouse tables.

---

## Dimensional Modeling Standards

### Dimensions

* Surrogate key as primary key.
* Natural key preserved as an alternate key when appropriate.
* Descriptive attributes belong in dimensions.
* Slowly Changing Dimension support may be added in future phases.

### Facts

* Store measurable business events.
* Foreign keys must reference dimensions.
* Avoid duplicate fact records.
* Facts should be additive whenever practical.

---

## Reporting Standards

* Reporting views should expose business-friendly column names.
* Hide implementation details from reporting consumers.
* Reporting queries should use Reporting views rather than direct Fact or Dimension access.

---

## Git Standards

When creating or modifying database objects:

1. Create or update the object script.
2. Create or update supporting indexes when necessary.
3. Update documentation when architecture changes.
4. Keep commits focused and small.
5. Use meaningful commit messages.
6. Ensure deployment scripts execute in the proper dependency order.

---

## Future Enhancements

Planned future phases may include:

* NHL API integration
* Python ETL pipelines
* SSIS packages
* Power BI dashboards
* Automated testing
* CI/CD deployment pipelines
* Historical season loading
* Advanced analytics and reporting
