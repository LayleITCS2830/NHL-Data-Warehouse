USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE Fact.usp_LoadFactPlayerGameStats
    @LoadBatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO Fact.PlayerGameStats
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
        FROM Staging.PlayerGameStatsRaw AS s
        INNER JOIN Fact.Game AS g
            ON g.GameID = s.GameID
        INNER JOIN Dimension.Player AS p
            ON p.PlayerID = s.PlayerID
        INNER JOIN Dimension.Team AS t
            ON t.TeamID = s.TeamID
        WHERE s.LoadBatchID = @LoadBatchID
          AND NOT EXISTS
          (
              SELECT 1
              FROM Fact.PlayerGameStats AS tgt
              WHERE tgt.GameKey = g.GameKey
                AND tgt.PlayerKey = p.PlayerKey
          );

        SET @RowsInserted = @@ROWCOUNT;

        EXEC Audit.usp_EndLoadBatch @LoadBatchID, 'Succeeded', @RowsInserted, 0, NULL;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        EXEC Audit.usp_EndLoadBatch @LoadBatchID, 'Failed', @RowsInserted, 0, ERROR_MESSAGE;
        THROW;
    END CATCH
END
GO
