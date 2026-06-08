USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE Fact.usp_LoadFactGame
    @LoadBatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Fact.Game
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
        FROM Staging.GameRaw AS g
        INNER JOIN Dimension.Team AS ht
            ON ht.TeamID = g.HomeTeamID
        INNER JOIN Dimension.Team AS at
            ON at.TeamID = g.AwayTeamID
        INNER JOIN Dimension.[Date] AS d
            ON d.FullDate = g.GameDate
        WHERE g.LoadBatchID = @LoadBatchID
          AND g.GameID IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM Fact.Game AS tgt
              WHERE tgt.GameID = g.GameID
          );

        SET @RowsInserted = @@ROWCOUNT;

        EXEC Audit.usp_EndLoadBatch @LoadBatchID, 'Succeeded', @RowsInserted, 0, NULL;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        EXEC Audit.usp_EndLoadBatch @LoadBatchID, 'Failed', @RowsInserted, 0, @ErrorMessage;
        THROW;
    END CATCH
END
GO
