# NHL Data Warehouse C# ETL

This folder contains a .NET console ETL option for loading NHL API data into the SQL Server warehouse. It follows the same warehouse contract as the Python ETL: source data is staged first, then the existing dimension and fact stored procedures load warehouse tables.

## Setup

Install the .NET 8 SDK and restore packages:

```powershell
cd ETL\CSharp
dotnet restore
```

Set a full connection string, or use the individual connection environment variables documented in `config.example.env`.

```powershell
$env:NHL_DW_CONNECTION_STRING = "Server=localhost;Database=NHLDataWarehouse;Trusted_Connection=True;TrustServerCertificate=True;"
```

## Commands

Run all source ETL steps in dependency order:

```powershell
dotnet run -- all
```

Run individual loaders:

```powershell
dotnet run -- teams
dotnet run -- players --team-abbrevs TOR,BOS
dotnet run -- games --start-date 2024-10-04 --end-date 2024-10-10
dotnet run -- player-stats --game-ids 2024020001,2024020002
```

Replay warehouse load procedures from the latest staging batches:

```powershell
dotnet run -- replay-procedures
```

You can also replay procedures after source ETL completes:

```powershell
dotnet run -- all --include-load-procedures
```

## Notes

- Staging tables are truncated before each matching source load.
- Each load starts a new `audit.LOAD_BATCH` row.
- Warehouse loads are performed by the existing stored procedures.
- Duplicate validation returns a nonzero process exit code when a check fails.
