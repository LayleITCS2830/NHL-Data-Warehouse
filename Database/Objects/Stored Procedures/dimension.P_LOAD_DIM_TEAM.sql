USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE dimension.P_LOAD_DIM_TEAM
    @load_batch_id UNIQUEIDENTIFIER
AS
/*****************************************************************************************
PROC:	dimension.P_LOAD_DIM_TEAM
AUTHOR:	Andrew Layle
DATE:	06/09/2026

DESCRIPTION:
    Loads team records from staging.team_raw into dimension.team_dim. Updates changed
    teams and inserts new teams while preserving the source team_id natural key.

INPUT PARAMETERS:
    @load_batch_id UNIQUEIDENTIFIER - The load batch identifier used to filter source rows.

*****************************************************************************************/

SET NOCOUNT ON
SET XACT_ABORT ON

DECLARE @rows_inserted INT = 0,
        @rows_updated INT = 0

BEGIN TRY
    BEGIN TRANSACTION

    UPDATE tgt
    SET team_name = src.team_name,
        team_abbreviation = src.team_abbreviation,
        conference = src.conference,
        division = src.division,
        is_active = 1,
        modified_date = SYSUTCDATETIME()
    FROM    dimension.team_dim  tgt
    JOIN    staging.team_raw    src ON  src.team_id = tgt.team_id
    WHERE   src.load_batch_id = @load_batch_id
    AND     src.team_id IS NOT NULL
    AND     src.team_name IS NOT NULL
    AND     (   ISNULL(tgt.team_name, '') <> ISNULL(src.team_name, '')
            OR  ISNULL(tgt.team_abbreviation, '') <> ISNULL(src.team_abbreviation, '')
            OR  ISNULL(tgt.conference, '') <> ISNULL(src.conference, '')
            OR  ISNULL(tgt.division, '') <> ISNULL(src.division, '')
            OR  tgt.is_active <> 1
        )

    SET @rows_updated = @@ROWCOUNT

    INSERT INTO dimension.team_dim
            (team_id, 
            team_name,
            team_abbreviation, 
            conference, 
            division)
    SELECT  src.team_id,
            src.team_name,
            src.team_abbreviation,
            src.conference,
            src.division
    FROM    staging.team_raw   src
    WHERE   src.load_batch_id = @load_batch_id
    AND     src.team_id IS NOT NULL
    AND     src.team_name IS NOT NULL
    AND     NOT EXISTS  (
                            SELECT  1
                            FROM    dimension.team_dim      tgt
                            WHERE   tgt.team_id = src.team_id
                        )

    SET @rows_inserted = @@ROWCOUNT

    EXEC audit.P_END_LOAD_BATCH @load_batch_id, 'Succeeded', @rows_inserted, @rows_updated, NULL
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE()

    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    EXEC audit.P_END_LOAD_BATCH @load_batch_id, 'Failed', @rows_inserted, @rows_updated, @error_message
    ;THROW
END CATCH
GO
