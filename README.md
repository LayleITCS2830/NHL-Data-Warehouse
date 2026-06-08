# NHL Data Warehouse

## Overview

The NHL Data Warehouse is a SQL Server 2022 portfolio project designed to demonstrate professional data warehousing, ETL, dimensional modeling, and reporting practices.

This project follows a traditional data warehouse architecture using staging, dimension, fact, reporting, and audit layers. The goal is to simulate the design patterns commonly used in enterprise analytics environments while using publicly available NHL hockey data.

The project is being developed as a learning and portfolio initiative to showcase skills in:

* SQL Server Development
* Data Warehousing
* ETL Design
* Dimensional Modeling
* Stored Procedure Development
* Data Quality and Auditing
* Reporting and Analytics

---

## Technology Stack

| Technology                          | Purpose                        |
| ----------------------------------- | ------------------------------ |
| SQL Server 2022                     | Database Platform              |
| SQL Server Management Studio (SSMS) | Development and Administration |
| GitHub                              | Source Control                 |
| T-SQL                               | Database Development           |
| SQLCMD                              | Database Deployment            |

Future enhancements may include:

* Python-based NHL API ingestion
* Power BI dashboards
* SSIS packages
* Automated CI/CD deployment pipelines

---

## Architecture

The warehouse follows a layered architecture:

```text
NHL API
    ↓
Staging Layer
    ↓
Dimension Layer
    ↓
Fact Layer
    ↓
Reporting Views
    ↓
Analytics / Power BI
```

---

## Database Schemas

### Staging

Stores raw source data before transformation.

Examples:

* Staging.TeamRaw
* Staging.PlayerRaw
* Staging.GameRaw
* Staging.PlayerGameStatsRaw

---

### Dimension

Stores descriptive business entities.

Examples:

* Dimension.Date
* Dimension.Team
* Dimension.Player

---

### Fact

Stores measurable business events.

Examples:

* Fact.Game
* Fact.PlayerGameStats

---

### Reporting

Contains business-friendly views for reporting and analytics.

Examples:

* Reporting.vwTeamGameResults
* Reporting.vwPlayerGameStats
* Reporting.vwTeamSeasonSummary
* Reporting.vwPlayerSeasonSummary

---

### Audit

Tracks ETL execution and load history.

Examples:

* Audit.LoadBatch

---

## Project Structure

```text
Database/
│
├── Deploy.sql
├── 001_CreateDatabase.sql
├── 002_CreateSchemas.sql
│
└── Objects/
    ├── Tables/
    ├── Stored Procedures/
    ├── Views/
    └── SampleData/
```

---

## Deployment

### Prerequisites

* SQL Server 2022
* SQL Server Management Studio (SSMS)

### Deploy Database

1. Open SSMS.
2. Enable SQLCMD Mode.

```text
Query → SQLCMD Mode
```

3. Open:

```text
Database/Deploy.sql
```

4. Execute the script.

The deployment script will:

* Create the database
* Create schemas
* Create tables
* Create stored procedures
* Create reporting views

---

## Core Tables

### Dimension.Date

Provides a reusable calendar dimension used throughout the warehouse.

### Dimension.Team

Stores NHL team information.

### Dimension.Player

Stores NHL player information.

### Fact.Game

Stores game-level statistics.

### Fact.PlayerGameStats

Stores player performance statistics by game.

### Audit.LoadBatch

Stores ETL execution history and audit information.

---

## ETL Process

The ETL framework is designed around stored procedures.

Key procedures include:

* Audit.usp_StartLoadBatch
* Audit.usp_EndLoadBatch
* Dimension.usp_LoadDimTeam
* Dimension.usp_LoadDimPlayer
* Dimension.usp_PopulateDateDimension
* Fact.usp_LoadFactGame
* Fact.usp_LoadFactPlayerGameStats

Design goals:

* Rerunnable loads
* Error handling
* Audit logging
* Duplicate prevention
* Transactional consistency

---

## Reporting Views

The reporting layer provides simplified access to warehouse data.

Examples include:

### Reporting.vwTeamGameResults

Game-level team performance metrics.

### Reporting.vwPlayerGameStats

Player-level game statistics.

### Reporting.vwTeamSeasonSummary

Season-level team summaries.

### Reporting.vwPlayerSeasonSummary

Season-level player summaries.

---

## Future Enhancements

Planned enhancements include:

* NHL API integration
* Automated data ingestion
* Historical season loading
* Power BI dashboards
* Advanced player analytics
* Team performance trend analysis
* CI/CD deployment pipeline
* Data quality monitoring

---

## Author

Andrew Layle

Data professional with experience in:

* SQL Server Development
* ETL Development
* Data Warehousing
* Reporting and Analytics
* Business Process Improvement

This project serves as a practical demonstration of enterprise-style database design and data engineering principles.
