/*
    Removes the illustrative NHL sample data loaded by 001_InsertSampleData.sql.
    Deletes warehouse rows in reverse dependency order and preserves shared rows
    that are still referenced by non-sample data.
*/
USE NHLDataWarehouse;
GO

DECLARE @TeamLoadBatchID UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @PlayerLoadBatchID UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222222';
DECLARE @GameLoadBatchID UNIQUEIDENTIFIER = '33333333-3333-3333-3333-333333333333';
DECLARE @PlayerGameStatsLoadBatchID UNIQUEIDENTIFIER = '44444444-4444-4444-4444-444444444444';

BEGIN TRY
    BEGIN TRANSACTION;

    -- Remove sample player statistics before games, players, and teams.
    DELETE pgs
    FROM fact.PLAYER_GAME_STATS_FACT AS pgs
    INNER JOIN fact.GAME_FACT AS g
        ON g.GameKey = pgs.GameKey
    WHERE g.GameID IN (2024020001, 2024020002, 2024020003);

    -- Remove sample games after dependent player statistics are gone.
    DELETE g
    FROM fact.GAME_FACT AS g
    WHERE g.GameID IN (2024020001, 2024020002, 2024020003);

    -- Remove sample players only when no facts still reference them.
    DELETE p
    FROM dimension.PLAYER_DIM AS p
    WHERE p.PlayerID IN
    (
        8478403, 8473419, 8479318, 8478483,
        8478048, 8480069, 8476453, 8475167
    )
      AND NOT EXISTS
      (
          SELECT 1
          FROM fact.PLAYER_GAME_STATS_FACT AS pgs
          WHERE pgs.PlayerKey = p.PlayerKey
      );

    -- Remove sample teams only when no players or facts still reference them.
    DELETE t
    FROM dimension.TEAM_DIM AS t
    WHERE t.TeamID IN (6, 10, 3, 14)
      AND NOT EXISTS
      (
          SELECT 1
          FROM dimension.PLAYER_DIM AS p
          WHERE p.TeamKey = t.TeamKey
      )
      AND NOT EXISTS
      (
          SELECT 1
          FROM fact.GAME_FACT AS g
          WHERE g.HomeTeamKey = t.TeamKey
             OR g.AwayTeamKey = t.TeamKey
      )
      AND NOT EXISTS
      (
          SELECT 1
          FROM fact.PLAYER_GAME_STATS_FACT AS pgs
          WHERE pgs.TeamKey = t.TeamKey
      );

    -- Remove sample staging rows.
    DELETE FROM staging.PLAYER_GAME_STATS_RAW
    WHERE LoadBatchID = @PlayerGameStatsLoadBatchID;

    DELETE FROM staging.GAME_RAW
    WHERE LoadBatchID = @GameLoadBatchID;

    DELETE FROM staging.PLAYER_RAW
    WHERE LoadBatchID = @PlayerLoadBatchID;

    DELETE FROM staging.TEAM_RAW
    WHERE LoadBatchID = @TeamLoadBatchID;

    -- Remove sample audit rows after the staged data has been removed.
    DELETE FROM audit.LOAD_BATCH
    WHERE LoadBatchID IN
    (
        @TeamLoadBatchID,
        @PlayerLoadBatchID,
        @GameLoadBatchID,
        @PlayerGameStatsLoadBatchID
    );

    -- Remove sample date rows only when no fact rows still reference them.
    DELETE d
    FROM dimension.DATE_DIM AS d
    WHERE d.FullDate >= '2024-10-01'
      AND d.FullDate <= '2024-10-31'
      AND NOT EXISTS
      (
          SELECT 1
          FROM fact.GAME_FACT AS g
          WHERE g.DateKey = d.DateKey
      );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO
