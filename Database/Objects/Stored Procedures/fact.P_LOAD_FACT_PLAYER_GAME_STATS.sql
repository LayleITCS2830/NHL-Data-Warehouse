USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE fact.P_LOAD_FACT_PLAYER_GAME_STATS
    @LoadBatchID UNIQUEIDENTIFIER
AS
/*****************************************************************************************
PROC:	fact.P_LOAD_FACT_PLAYER_GAME_STATS
AUTHOR:	Andrew Layle
DATE:	06/09/2026

DESCRIPTION:
    Loads player game statistics from staging.PLAYER_GAME_STATS_RAW into
    fact.PLAYER_GAME_STATS_FACT. Inserts new player/game combinations only.

INPUT PARAMETERS:
    @LoadBatchID UNIQUEIDENTIFIER - The load batch identifier used to filter source rows.

*****************************************************************************************/
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO fact.PLAYER_GAME_STATS_FACT
            (GameKey, PlayerKey, TeamKey, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
        SELECT g.GameKey,
               p.PlayerKey,
               t.TeamKey,
               COALESCE(s.Goals, 0),
               COALESCE(s.Assists, 0),
               COALESCE(s.Shots, 0),
               COALESCE(s.Hits, 0),
               COALESCE(s.Blocks, 0),
               COALESCE(s.PenaltyMinutes, 0),
               s.TimeOnIceSeconds
        FROM staging.PLAYER_GAME_STATS_RAW AS s
        INNER JOIN fact.GAME_FACT AS g
            ON g.GameID = s.GameID
        INNER JOIN dimension.PLAYER_DIM AS p
            ON p.PlayerID = s.PlayerID
        INNER JOIN dimension.TEAM_DIM AS t
            ON t.TeamID = s.TeamID
        WHERE s.LoadBatchID = @LoadBatchID
          AND NOT EXISTS
          (
              SELECT 1
              FROM fact.PLAYER_GAME_STATS_FACT AS tgt
              WHERE tgt.GameKey = g.GameKey
                AND tgt.PlayerKey = p.PlayerKey
          );

        SET @RowsInserted = @@ROWCOUNT;

        EXEC audit.P_END_LOAD_BATCH @LoadBatchID, 'Succeeded', @RowsInserted, 0, NULL;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        EXEC audit.P_END_LOAD_BATCH @LoadBatchID, 'Failed', @RowsInserted, 0, @ErrorMessage;
        THROW;
    END CATCH
END
GO
