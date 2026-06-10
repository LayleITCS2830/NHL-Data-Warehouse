USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE fact.P_LOAD_FACT_GAME
    @load_batch_id UNIQUEIDENTIFIER
AS
/*****************************************************************************************
PROC:	fact.P_LOAD_FACT_GAME
AUTHOR:	Andrew Layle
DATE:	06/09/2026

DESCRIPTION:
    Loads game records from staging.game_raw into fact.game_fact. Inserts new games only
    after resolving date and team dimension surrogate keys.

INPUT PARAMETERS:
    @load_batch_id UNIQUEIDENTIFIER - The load batch identifier used to filter source rows.

*****************************************************************************************/

SET NOCOUNT ON
SET XACT_ABORT ON

DECLARE @rows_inserted INT = 0

BEGIN TRY
    BEGIN TRANSACTION

    INSERT INTO fact.game_fact
            (game_id, date_key, season, game_type, home_team_key, away_team_key, 
            home_goals, away_goals, home_shots, away_shots)
    SELECT  g.game_id, CONVERT(INT, FORMAT(g.game_date, 'yyyyMMdd')), g.season, g.game_type, ht.team_key, at.team_key,
            g.home_goals, g.away_goals, g.home_shots, g.away_shots
    FROM    staging.game_raw       g
    JOIN    dimension.team_dim     ht  ON  ht.team_id = g.home_team_id
    JOIN    dimension.team_dim     at  ON  at.team_id = g.away_team_id
    JOIN    dimension.date_dim     d   ON  d.full_date = g.game_date
    WHERE   g.load_batch_id = @load_batch_id
    AND     g.game_id IS NOT NULL
    AND     NOT EXISTS
        (
            SELECT 1
            FROM fact.game_fact AS tgt
            WHERE tgt.game_id = g.game_id
        )

    SET @rows_inserted = @@ROWCOUNT

    EXEC audit.P_END_LOAD_BATCH @load_batch_id, 'Succeeded', @rows_inserted, 0, NULL;
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE();

    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    EXEC audit.P_END_LOAD_BATCH @load_batch_id, 'Failed', @rows_inserted, 0, @error_message
    ;THROW
END CATCH

GO
