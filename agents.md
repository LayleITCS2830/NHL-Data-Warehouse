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

## Architecture

### Schemas

* Staging
* Dimension
* Fact
* Reporting
* Audit

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
* Separate staging, warehouse, audit, and reporting objects by schema.
* Do not place warehouse objects in dbo unless explicitly required.

---

## Naming Standards

### Tables

```sql
Dimension.Team
Dimension.Player
Fact.Game
Fact.PlayerGameStats
Staging.TeamRaw
```

### Views

```sql
Reporting.vwTeamSeasonSummary
Reporting.vwPlayerGameStats
```

### Stored Procedures

```sql
Dimension.usp_LoadDimTeam
Dimension.usp_LoadDimPlayer
Fact.usp_LoadFactGame
Fact.usp_LoadFactPlayerGameStats
```

### Constraints

```text
PK_TableName
FK_Child_Parent
UQ_Table_Column
```

---

## Code Standards

* Use SET NOCOUNT ON in stored procedures.
* Avoid SELECT *.
* Explicitly list columns in INSERT statements.
* Use TRY/CATCH error handling.
* Use transactions when modifying warehouse data.
* Write rerunnable deployment scripts whenever practical.
* Use schema-qualified object references.
* Use meaningful aliases.

---

## Indexing Standards

* Every table must have a named primary key.
* Evaluate foreign key columns for indexing.
* Create indexes only when there is a clear query or join benefit.
* Choose clustered indexes intentionally.
* Document non-obvious indexes with comments.

---

## ETL Standards

All ETL procedures must:

* Support reruns.
* Prevent duplicate records.
* Log execution activity to Audit.LoadBatch.
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
