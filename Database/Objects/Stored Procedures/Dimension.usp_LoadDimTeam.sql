USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE Dimension.usp_LoadDimTeam
    @LoadBatchID UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0, @RowsUpdated INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE tgt
        SET TeamName = src.TeamName,
            TeamAbbreviation = src.TeamAbbreviation,
            Conference = src.Conference,
            Division = src.Division,
            IsActive = 1,
            ModifiedDate = SYSUTCDATETIME()
        FROM Dimension.Team AS tgt
        INNER JOIN Staging.TeamRaw AS src
            ON src.TeamID = tgt.TeamID
        WHERE src.LoadBatchID = @LoadBatchID
          AND src.TeamID IS NOT NULL
          AND src.TeamName IS NOT NULL
          AND (
                ISNULL(tgt.TeamName, '') <> ISNULL(src.TeamName, '')
             OR ISNULL(tgt.TeamAbbreviation, '') <> ISNULL(src.TeamAbbreviation, '')
             OR ISNULL(tgt.Conference, '') <> ISNULL(src.Conference, '')
             OR ISNULL(tgt.Division, '') <> ISNULL(src.Division, '')
             OR tgt.IsActive <> 1
          );

        SET @RowsUpdated = @@ROWCOUNT;

        INSERT INTO Dimension.Team (TeamID, TeamName, TeamAbbreviation, Conference, Division)
        SELECT src.TeamID, src.TeamName, src.TeamAbbreviation, src.Conference, src.Division
        FROM Staging.TeamRaw AS src
        WHERE src.LoadBatchID = @LoadBatchID
          AND src.TeamID IS NOT NULL
          AND src.TeamName IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM Dimension.Team AS tgt
              WHERE tgt.TeamID = src.TeamID
          );

        SET @RowsInserted = @@ROWCOUNT;

        EXEC Audit.usp_EndLoadBatch @LoadBatchID, 'Succeeded', @RowsInserted, @RowsUpdated, NULL;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        EXEC Audit.usp_EndLoadBatch @LoadBatchID, 'Failed', @RowsInserted, @RowsUpdated, @ErrorMessage;
        THROW;
    END CATCH
END
GO
