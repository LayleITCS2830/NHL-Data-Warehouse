/*
    Deploys the NHLDataWarehouse database.
    Run this script from the Database folder in SQLCMD mode.
*/
:on error exit

-- Create database and schemas
:r .\001_CreateDatabase.sql
:r .\002_CreateSchemas.sql

-- Create tables
:r ".\Objects\Tables\audit.load_batch.sql"
:r ".\Objects\Tables\dimension.date_dim.sql"
:r ".\Objects\Tables\dimension.team_dim.sql"
:r ".\Objects\Tables\dimension.player_dim.sql"
:r ".\Objects\Tables\fact.game_fact.sql"
:r ".\Objects\Tables\fact.player_game_stats_fact.sql"
:r ".\Objects\Tables\staging.game_raw.sql"
:r ".\Objects\Tables\staging.player_raw.sql"
:r ".\Objects\Tables\staging.player_game_stats_raw.sql"
:r ".\Objects\Tables\staging.team_raw.sql"

-- Create stored procedures
:r ".\Objects\Stored Procedures\audit.P_START_LOAD_BATCH.sql"
:r ".\Objects\Stored Procedures\audit.P_END_LOAD_BATCH.sql"
:r ".\Objects\Stored Procedures\dimension.P_LOAD_DIM_TEAM.sql"
:r ".\Objects\Stored Procedures\dimension.P_LOAD_DIM_PLAYER.sql"
:r ".\Objects\Stored Procedures\dimension.P_POPULATE_DATE_DIMENSION.sql"
:r ".\Objects\Stored Procedures\fact.P_LOAD_FACT_GAME.sql"
:r ".\Objects\Stored Procedures\fact.P_LOAD_FACT_PLAYER_GAME_STATS.sql"

-- Create reporting views
:r ".\Objects\Views\reporting.vw_team_game_results.sql"
:r ".\Objects\Views\reporting.vw_player_game_stats.sql"
:r ".\Objects\Views\reporting.vw_team_season_summary.sql"
:r ".\Objects\Views\reporting.vw_player_season_summary.sql"

-- Optional sample data
-- :r ".\004_LoadSampleData.sql"
