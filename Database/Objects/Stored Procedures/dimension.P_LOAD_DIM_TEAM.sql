USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE dimension.P_LOAD_DIM_TEAM
    @LoadBatchID UNIQUEIDENTIFIER
AS
/*****************************************************************************************
PROC:	dimension.P_LOAD_DIM_TEAM
AUTHOR:	Andrew Layle
DATE:	06/09/2026

DESCRIPTION:
    Loads team records from staging.TEAM_RAW into dimension.TEAM_DIM. Updates changed
    teams and inserts new teams while preserving the source TeamID natural key.

INPUT PARAMETERS:
    @LoadBatchID UNIQUEIDENTIFIER - The load batch identifier used to filter source rows.

*****************************************************************************************/
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0,
            @RowsUpdated INT = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE tgt
        SET TeamName = src.TeamName,
            TeamAbbreviation = src.TeamAbbreviation,
            Conference = src.Conference,
            Division = src.Division,
            IsActive = 1,
            ModifiedDate = SYSUTCDATETIME()
        FROM dimension.TEAM_DIM AS tgt
        INNER JOIN staging.TEAM_RAW AS src
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

        INSERT INTO dimension.TEAM_DIM
            (TeamID, TeamName, TeamAbbreviation, Conference, Division)
        SELECT src.TeamID,
               src.TeamName,
               src.TeamAbbreviation,
               src.Conference,
               src.Division
        FROM staging.TEAM_RAW AS src
        WHERE src.LoadBatchID = @LoadBatchID
          AND src.TeamID IS NOT NULL
          AND src.TeamName IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM dimension.TEAM_DIM AS tgt
              WHERE tgt.TeamID = src.TeamID
          );

        SET @RowsInserted = @@ROWCOUNT;

        EXEC audit.P_END_LOAD_BATCH @LoadBatchID, 'Succeeded', @RowsInserted, @RowsUpdated, NULL;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();

        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        EXEC audit.P_END_LOAD_BATCH @LoadBatchID, 'Failed', @RowsInserted, @RowsUpdated, @ErrorMessage;
        THROW;
    END CATCH
END
GO
