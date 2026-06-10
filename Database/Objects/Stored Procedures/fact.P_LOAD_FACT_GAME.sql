USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE fact.P_LOAD_FACT_GAME
    @LoadBatchID UNIQUEIDENTIFIER
AS
/*****************************************************************************************
PROC:	fact.P_LOAD_FACT_GAME
AUTHOR:	Andrew Layle
DATE:	06/09/2026

DESCRIPTION:
    Loads game records from staging.GAME_RAW into fact.GAME_FACT. Inserts new games only
    after resolving date and team dimension surrogate keys.

INPUT PARAMETERS:
    @LoadBatchID UNIQUEIDENTIFIER - The load batch identifier used to filter source rows.

*****************************************************************************************/
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO fact.GAME_FACT
            (GameID, DateKey, Season, GameType, HomeTeamKey, AwayTeamKey, HomeGoals, AwayGoals, HomeShots, AwayShots)
        SELECT g.GameID,
               CONVERT(INT, FORMAT(g.GameDate, 'yyyyMMdd')),
               g.Season,
               g.GameType,
               ht.TeamKey,
               at.TeamKey,
               g.HomeGoals,
               g.AwayGoals,
               g.HomeShots,
               g.AwayShots
        FROM staging.GAME_RAW AS g
        INNER JOIN dimension.TEAM_DIM AS ht
            ON ht.TeamID = g.HomeTeamID
        INNER JOIN dimension.TEAM_DIM AS at
            ON at.TeamID = g.AwayTeamID
        INNER JOIN dimension.DATE_DIM AS d
            ON d.FullDate = g.GameDate
        WHERE g.LoadBatchID = @LoadBatchID
          AND g.GameID IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM fact.GAME_FACT AS tgt
              WHERE tgt.GameID = g.GameID
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
