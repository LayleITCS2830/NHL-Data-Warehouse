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
        ON g.GAME_KEY = pgs.GAME_KEY
    WHERE g.GAME_ID IN (2024020001, 2024020002, 2024020003);

    -- Remove sample games after dependent player statistics are gone.
    DELETE g
    FROM fact.GAME_FACT AS g
    WHERE g.GAME_ID IN (2024020001, 2024020002, 2024020003);

    -- Remove sample players only when no facts still reference them.
    DELETE p
    FROM dimension.PLAYER_DIM AS p
    WHERE p.PLAYER_ID IN
    (
        8478403, 8473419, 8479318, 8478483,
        8478048, 8480069, 8476453, 8475167
    )
      AND NOT EXISTS
      (
          SELECT 1
          FROM fact.PLAYER_GAME_STATS_FACT AS pgs
          WHERE pgs.PLAYER_KEY = p.PLAYER_KEY
      );

    -- Remove sample teams only when no players or facts still reference them.
    DELETE t
    FROM dimension.TEAM_DIM AS t
    WHERE t.TEAM_ID IN (6, 10, 3, 14)
      AND NOT EXISTS
      (
          SELECT 1
          FROM dimension.PLAYER_DIM AS p
          WHERE p.TEAM_KEY = t.TEAM_KEY
      )
      AND NOT EXISTS
      (
          SELECT 1
          FROM fact.GAME_FACT AS g
          WHERE g.HOME_TEAM_KEY = t.TEAM_KEY
             OR g.AWAY_TEAM_KEY = t.TEAM_KEY
      )
      AND NOT EXISTS
      (
          SELECT 1
          FROM fact.PLAYER_GAME_STATS_FACT AS pgs
          WHERE pgs.TEAM_KEY = t.TEAM_KEY
      );

    -- Remove sample staging rows.
    DELETE FROM staging.PLAYER_GAME_STATS_RAW
    WHERE LOAD_BATCH_ID = @PlayerGameStatsLoadBatchID;

    DELETE FROM staging.GAME_RAW
    WHERE LOAD_BATCH_ID = @GameLoadBatchID;

    DELETE FROM staging.PLAYER_RAW
    WHERE LOAD_BATCH_ID = @PlayerLoadBatchID;

    DELETE FROM staging.TEAM_RAW
    WHERE LOAD_BATCH_ID = @TeamLoadBatchID;

    -- Remove sample audit rows after the staged data has been removed.
    DELETE FROM audit.LOAD_BATCH
    WHERE LOAD_BATCH_ID IN
    (
        @TeamLoadBatchID,
        @PlayerLoadBatchID,
        @GameLoadBatchID,
        @PlayerGameStatsLoadBatchID
    );

    -- Remove sample date rows only when no fact rows still reference them.
    DELETE d
    FROM dimension.DATE_DIM AS d
    WHERE d.FULL_DATE >= '2024-10-01'
      AND d.FULL_DATE <= '2024-10-31'
      AND NOT EXISTS
      (
          SELECT 1
          FROM fact.GAME_FACT AS g
          WHERE g.DATE_KEY = d.DATE_KEY
      );

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH
GO
