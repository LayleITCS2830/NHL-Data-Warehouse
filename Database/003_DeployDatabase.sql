/*
    Deploys the NHLDataWarehouse database.
    Run this script from the Database folder in SQLCMD mode.
*/
:on error exit

-- Create database and schemas
:r .\001_CreateDatabase.sql
:r .\002_CreateSchemas.sql

-- Create tables
:r ".\Objects\Tables\audit.LOAD_BATCH.sql"
:r ".\Objects\Tables\dimension.DATE_DIM.sql"
:r ".\Objects\Tables\dimension.TEAM_DIM.sql"
:r ".\Objects\Tables\dimension.PLAYER_DIM.sql"
:r ".\Objects\Tables\fact.GAME_FACT.sql"
:r ".\Objects\Tables\fact.PLAYER_GAME_STATS_FACT.sql"
:r ".\Objects\Tables\staging.GAME_RAW.sql"
:r ".\Objects\Tables\staging.PLAYER_RAW.sql"
:r ".\Objects\Tables\staging.PLAYER_GAME_STATS_RAW.sql"
:r ".\Objects\Tables\staging.TEAM_RAW.sql"

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
