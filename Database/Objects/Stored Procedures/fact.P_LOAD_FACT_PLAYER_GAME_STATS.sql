USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE fact.P_LOAD_FACT_PLAYER_GAME_STATS
    @load_batch_id UNIQUEIDENTIFIER
AS
/*****************************************************************************************
PROC:	fact.P_LOAD_FACT_PLAYER_GAME_STATS
AUTHOR:	Andrew Layle
DATE:	06/09/2026

DESCRIPTION:
    Loads player game statistics from staging.player_game_stats_raw into
    fact.player_game_stats_fact. Inserts new player/game combinations only.

INPUT PARAMETERS:
    @load_batch_id UNIQUEIDENTIFIER - The load batch identifier used to filter source rows.

*****************************************************************************************/
SET NOCOUNT ON
SET XACT_ABORT ON

DECLARE @rows_inserted INT = 0

BEGIN TRY
    BEGIN TRANSACTION

    INSERT INTO fact.player_game_stats_fact
            (game_key, player_key, team_key, 
            goals, 
            assists, 
            shots, 
            hits, 
            blocks, 
            penalty_minutes, 
            time_on_ice_seconds)
    SELECT  g.game_key, p.player_key, t.team_key,
            ISNULL(s.goals, 0),
            ISNULL(s.assists, 0),
            ISNULL(s.shots, 0),
            ISNULL(s.hits, 0),
            ISNULL(s.blocks, 0),
            ISNULL(s.penalty_minutes, 0),
            s.time_on_ice_seconds
    FROM    staging.player_game_stats_raw   s
    JOIN    fact.game_fact                  g   ON  g.game_id = s.game_id
    JOIN    dimension.player_dim            p   ON  p.player_id = s.player_id
    JOIN    dimension.team_dim              t   ON  t.team_id = s.team_id
    WHERE   s.load_batch_id = @load_batch_id
    AND NOT EXISTS  (
                        SELECT  1
                        FROM    fact.player_game_stats_fact tgt
                        WHERE   tgt.game_key = g.game_key
                        AND     tgt.player_key = p.player_key
                        AND     tgt.team_key = t.team_key
                    )

    SET @rows_inserted = @@ROWCOUNT

    EXEC audit.P_END_LOAD_BATCH @load_batch_id, 'Succeeded', @rows_inserted, 0, NULL
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    DECLARE @error_message NVARCHAR(MAX) = ERROR_MESSAGE()

    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
    EXEC audit.P_END_LOAD_BATCH @load_batch_id, 'Failed', @rows_inserted, 0, @error_message
    THROW
END CATCH

GO
