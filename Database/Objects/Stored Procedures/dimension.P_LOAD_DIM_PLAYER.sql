USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE dimension.P_LOAD_DIM_PLAYER
    @LoadBatchID UNIQUEIDENTIFIER
AS
/*****************************************************************************************
PROC:	dimension.P_LOAD_DIM_PLAYER
AUTHOR:	Andrew Layle
DATE:	06/10/2026

DESCRIPTION:
    Loads player records from staging.PLAYER_RAW into dimension.PLAYER_DIM. Updates
    changed players and inserts new players while preserving the source PlayerID natural key.

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
            FROM staging.PLAYER_RAW AS p
            LEFT JOIN dimension.TEAM_DIM AS t
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
        FROM dimension.PLAYER_DIM AS tgt
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
            FROM staging.PLAYER_RAW AS p
            LEFT JOIN dimension.TEAM_DIM AS t
                ON t.TeamID = p.TeamID
            WHERE p.LoadBatchID = @LoadBatchID
              AND p.PlayerID IS NOT NULL
        )
        INSERT INTO dimension.PLAYER_DIM
            (PlayerID, TeamKey, FirstName, LastName, FullName, PositionCode, ShootsCatches, BirthDate)
        SELECT src.PlayerID,
               src.TeamKey,
               src.FirstName,
               src.LastName,
               src.FullName,
               src.PositionCode,
               src.ShootsCatches,
               src.BirthDate
        FROM SourceRows AS src
        WHERE src.FullName IS NOT NULL
          AND NOT EXISTS
          (
              SELECT 1
              FROM dimension.PLAYER_DIM AS tgt
              WHERE tgt.PlayerID = src.PlayerID
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
