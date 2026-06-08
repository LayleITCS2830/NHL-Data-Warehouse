USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE Dimension.usp_LoadDimPlayer
    @LoadBatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0, @RowsUpdated INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        WITH SourceRows AS
        (
            SELECT p.PlayerID,
                   t.TeamKey,
                   p.FirstName,
                   p.LastName,
                   COALESCE(NULLIF(p.FullName, ''), LTRIM(RTRIM(CONCAT(p.FirstName, ' ', p.LastName)))) AS FullName,
                   p.PositionCode,
                   p.ShootsCatches,
                   p.BirthDate
            FROM Staging.PlayerRaw AS p
            LEFT JOIN Dimension.Team AS t
                ON t.TeamID = p.TeamID
            WHERE p.LoadBatchID = @LoadBatchID
              AND p.PlayerID IS NOT NULL
        )
        UPDATE tgt
        SET TeamKey = src.TeamKey,
            FirstName = src.FirstName,
            LastName = src.LastName,
            FullName = src.FullName,
            PositionCode = src.PositionCode,
            ShootsCatches = src.ShootsCatches,
            BirthDate = src.BirthDate,
            IsActive = 1,
            ModifiedDate = SYSUTCDATETIME()
        FROM Dimension.Player AS tgt
        INNER JOIN SourceRows AS src
            ON src.PlayerID = tgt.PlayerID
        WHERE src.FullName IS NOT NULL
          AND (
                ISNULL(tgt.TeamKey, -1) <> ISNULL(src.TeamKey, -1)
             OR ISNULL(tgt.FirstName, '') <> ISNULL(src.FirstName, '')
             OR ISNULL(tgt.LastName, '') <> ISNULL(src.LastName, '')
             OR tgt.FullName <> src.FullName
             OR ISNULL(tgt.PositionCode, '') <> ISNULL(src.PositionCode, '')
             OR ISNULL(tgt.ShootsCatches, '') <> ISNULL(src.ShootsCatches, '')
             OR ISNULL(tgt.BirthDate, '19000101') <> ISNULL(src.BirthDate, '19000101')
             OR tgt.IsActive <> 1
          );

        SET @RowsUpdated = @@ROWCOUNT;

        WITH SourceRows AS
        (
            SELECT p.PlayerID,
                   t.TeamKey,
                   p.FirstName,
                   p.LastName,
                   COALESCE(NULLIF(p.FullName, ''), LTRIM(RTRIM(CONCAT(p.FirstName, ' ', p.LastName)))) AS FullName,
                   p.PositionCode,
                   p.ShootsCatches,
                   p.BirthDate
            FROM Staging.PlayerRaw AS p
            LEFT JOIN Dimension.Team AS t
                ON t.TeamID = p.TeamID
            WHERE p.LoadBatchID = @LoadBatchID
              AND p.PlayerID IS NOT NULL
        )
        INSERT INTO Dimension.Player
            (PlayerID, TeamKey, FirstName, LastName, FullName, PositionCode, ShootsCatches, BirthDate)
        SELECT src.PlayerID, src.TeamKey, src.FirstName, src.LastName, src.FullName,
               src.PositionCode, src.ShootsCatches, src.BirthDate
        FROM SourceRows AS src
        WHERE src.FullName IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM Dimension.Player AS tgt
              WHERE tgt.PlayerID = src.PlayerID
          );

        SET @RowsInserted = @@ROWCOUNT;

        EXEC Audit.usp_EndLoadBatch @LoadBatchID, 'Succeeded', @RowsInserted, @RowsUpdated, NULL;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        EXEC Audit.usp_EndLoadBatch @LoadBatchID, 'Failed', @RowsInserted, @RowsUpdated, ERROR_MESSAGE;
        THROW;
    END CATCH
END
GO
