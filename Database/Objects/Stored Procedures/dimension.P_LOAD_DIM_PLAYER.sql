USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE dimension.P_LOAD_DIM_PLAYER
    @load_batch_id UNIQUEIDENTIFIER
AS
/*****************************************************************************************
PROC:	dimension.P_LOAD_DIM_PLAYER
AUTHOR:	Andrew Layle
DATE:	06/10/2026

DESCRIPTION:
    Loads player records from staging.player_raw into dimension.player_dim. Updates
    changed players and inserts new players while preserving the source player_id natural key.

INPUT PARAMETERS:
    @load_batch_id UNIQUEIDENTIFIER - The load batch identifier used to filter source rows.

*****************************************************************************************/
SET NOCOUNT ON
SET XACT_ABORT ON

DECLARE @rows_inserted INT = 0,
        @rows_updated INT = 0

BEGIN TRY
    BEGIN TRANSACTION

    ;WITH source_rows AS
    (
        SELECT  p.player_id,
                t.team_key,
                p.first_name,
                p.last_name,
                ISNULL(NULLIF(p.full_name, ''), LTRIM(RTRIM(CONCAT(p.first_name, ' ', p.last_name)))) AS full_name,
                p.position_code,
                p.shoots_catches,
                p.birth_date
        FROM    staging.player_raw         p
        LEFT OUTER JOIN 
                dimension.team_dim    t   ON  t.team_id = p.team_id
        WHERE   p.load_batch_id = @load_batch_id
        AND     p.player_id IS NOT NULL
    )
    UPDATE  tgt
    SET team_key = src.team_key,
        first_name = src.first_name,
        last_name = src.last_name,
        full_name = src.full_name,
        position_code = src.position_code,
        shoots_catches = src.shoots_catches,
        birth_date = src.birth_date,
        is_active = 1,
        modified_date = SYSUTCDATETIME()
    FROM    dimension.player_dim        tgt
    JOIN    source_rows                 src ON  src.player_id = tgt.player_id
    WHERE   src.full_name IS NOT NULL
    AND     (ISNULL(tgt.team_key, -1) <> ISNULL(src.team_key, -1)
            OR  ISNULL(tgt.first_name, '') <> ISNULL(src.first_name, '')
            OR  ISNULL(tgt.last_name, '') <> ISNULL(src.last_name, '')
            OR  tgt.full_name <> src.full_name
            OR  ISNULL(tgt.position_code, '') <> ISNULL(src.position_code, '')
            OR  ISNULL(tgt.shoots_catches, '') <> ISNULL(src.shoots_catches, '')
            OR  ISNULL(tgt.birth_date, '19000101') <> ISNULL(src.birth_date, '19000101')
            OR  tgt.is_active <> 1
            )

    SET @rows_updated = @@ROWCOUNT

    ;WITH source_rows AS
    (
        SELECT  p.player_id,
                t.team_key,
                p.first_name,
                p.last_name,
                ISNULL(NULLIF(p.full_name, ''), LTRIM(RTRIM(CONCAT(p.first_name, ' ', p.last_name)))) AS full_name,
                p.position_code,
                p.shoots_catches,
                p.birth_date
        FROM    staging.player_raw  p
        LEFT OUTER JOIN
                dimension.team_dim  t   ON  t.team_id = p.team_id
        WHERE   p.load_batch_id = @load_batch_id
        AND     p.player_id IS NOT NULL
    )
    INSERT INTO dimension.player_dim
            (player_id, team_key, first_name, last_name, full_name, 
            position_code, shoots_catches, birth_date)
    SELECT  src.player_id, src.team_key, src.first_name, src.last_name, src.full_name,
            src.position_code, src.shoots_catches, src.birth_date
    FROM    source_rows     src
    WHERE   src.full_name IS NOT NULL
    AND     NOT EXISTS  (
                            SELECT  1
                            FROM    dimension.player_dim    tgt
                            WHERE   tgt.player_id = src.player_id
                        )

    SET @rows_inserted = @@ROWCOUNT

    EXEC audit.P_END_LOAD_BATCH @load_batch_id, 'Succeeded', @rows_inserted, @rows_updated, NULL
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE()

    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    EXEC audit.P_END_LOAD_BATCH @load_batch_id, 'Failed', @rows_inserted, @rows_updated, @error_message
    THROW
END CATCH

GO
