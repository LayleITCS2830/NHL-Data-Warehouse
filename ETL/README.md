# NHL Data Warehouse ETL

This folder contains Python ETL processes that load NHL API data into the SQL Server
data warehouse.

## Team Dimension ETL

The first Python ETL process loads NHL team records from the NHL API into the team
dimension.

Expected flow:

1. Start a load batch with `audit.P_START_LOAD_BATCH`.
2. Call the NHL teams endpoint.
3. Parse team records from the API response.
4. Insert parsed team records into `staging.TEAM_RAW`.
5. Execute `dimension.P_LOAD_DIM_TEAM`.
6. Prove no duplicate teams were created in `dimension.TEAM_DIM`.

Note: team data belongs in `staging.TEAM_RAW`. `dimension.P_LOAD_DIM_TEAM` reads from
`staging.TEAM_RAW`, so the teams ETL should not insert these rows into
`staging.PLAYER_RAW`.

## Database Contract

### Staging Target

`staging.TEAM_RAW`

Columns populated by the Python ETL:

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

`RAW_ID` and `CREATED_DATE` are populated by table defaults.

### Audit Start

```sql
DECLARE @load_batch_id UNIQUEIDENTIFIER;

EXEC audit.P_START_LOAD_BATCH
    @source_system = 'NHL API',
    @load_batch_id = @load_batch_id OUTPUT;
```

The returned `@load_batch_id` must be used for every staging row inserted during the
same ETL run.

### Dimension Load

```sql
EXEC dimension.P_LOAD_DIM_TEAM
    @load_batch_id = @load_batch_id;
```

`dimension.P_LOAD_DIM_TEAM` updates changed teams and inserts new teams by matching on
the NHL source natural key, `team_id`.

## Duplicate Proof

`dimension.TEAM_DIM` includes a unique constraint on the NHL source team identifier:

```sql
CONSTRAINT TEAM_DIM_TEAM_ID_uq UNIQUE (TEAM_ID)
```

After each ETL run, this query should return zero rows:

```sql
SELECT  team_id,
        COUNT(*) AS team_count
FROM    dimension.team_dim
GROUP BY team_id
HAVING  COUNT(*) > 1;
```

The ETL should also be rerunnable. Running the same team load twice should not increase
the count of records in `dimension.TEAM_DIM` for existing `team_id` values.

Suggested rerun proof:

```sql
SELECT COUNT(*) AS team_count_before
FROM   dimension.team_dim;

-- Run the Python team ETL again with the same NHL source data.

SELECT COUNT(*) AS team_count_after
FROM   dimension.team_dim;
```

`team_count_before` and `team_count_after` should match when the NHL source team list
has not changed.

## Python Implementation Notes

The Python process should:

* Use one `load_batch_id` per run.
* Store the raw JSON payload for each team in `raw_json`.
* Explicitly list target columns in every insert statement.
* Commit staging inserts before calling `dimension.P_LOAD_DIM_TEAM`, or use a single
  transaction that keeps the staged rows visible to the procedure.
* Let the stored procedure `NOT EXISTS` check and the `TEAM_DIM_TEAM_ID_uq` constraint
  prevent duplicate dimension rows.
* Record failures by ending the audit batch with a `Failed` status when an error occurs
  before `dimension.P_LOAD_DIM_TEAM` handles audit logging.

## Running the Team ETL

Install dependencies:

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

Run the load:

```powershell
python load_teams.py
```

Successful output includes the load batch identifier, parsed API team count, staging
insert count, dimension row counts before and after the load, and the number of duplicate
team check rows. `Duplicate team check rows` should be `0`.

## Planned File Layout

```text
ETL/
|-- README.md
|-- Python/
|   |-- load_teams.py
|   |-- requirements.txt
|   `-- config.example.env
`-- SSIS/
```
