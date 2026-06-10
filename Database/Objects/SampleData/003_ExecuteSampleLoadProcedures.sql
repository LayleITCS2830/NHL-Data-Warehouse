/*
    Executes all warehouse load procedures for the staged sample data.
    Run after 001_InsertSampleData.sql, or use Database/004_LoadSampleData.sql
    to clean, stage, and load in one SQLCMD run.
*/
USE NHLDataWarehouse;
GO

DECLARE @TeamLoadBatchID UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @PlayerLoadBatchID UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222222';
DECLARE @GameLoadBatchID UNIQUEIDENTIFIER = '33333333-3333-3333-3333-333333333333';
DECLARE @PlayerGameStatsLoadBatchID UNIQUEIDENTIFIER = '44444444-4444-4444-4444-444444444444';

-- Populate required dates before loading game facts.
EXEC dimension.P_POPULATE_DATE_DIMENSION
    @StartDate = '2024-10-01',
    @EndDate = '2024-10-31';

-- Load dimensions before facts.
EXEC dimension.P_LOAD_DIM_TEAM
    @LoadBatchID = @TeamLoadBatchID;

EXEC dimension.P_LOAD_DIM_PLAYER
    @LoadBatchID = @PlayerLoadBatchID;

-- Load facts after referenced dates, teams, and players exist.
EXEC fact.P_LOAD_FACT_GAME
    @LoadBatchID = @GameLoadBatchID;

EXEC fact.P_LOAD_FACT_PLAYER_GAME_STATS
    @LoadBatchID = @PlayerGameStatsLoadBatchID;

-- Show sample load results for a quick sanity check after execution.
SELECT SourceSystem,
       Status,
       RowsInserted,
       RowsUpdated,
       ErrorMessage
FROM audit.LOAD_BATCH
WHERE LoadBatchID IN
(
    @TeamLoadBatchID,
    @PlayerLoadBatchID,
    @GameLoadBatchID,
    @PlayerGameStatsLoadBatchID
)
ORDER BY LoadStartDate;
GO
