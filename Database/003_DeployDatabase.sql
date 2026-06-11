/*
    Deploys the NHLDataWarehouse database.
    Run this script from the Database folder in SQLCMD mode.
*/
:on error exit

-- Create database and schemas
:r C:\Workspace\NHLDataWarehouse\Database\001_CreateDatabase.sql
:r C:\Workspace\NHLDataWarehouse\Database\002_CreateSchemas.sql

-- Create tables
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Tables\audit.load_batch.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Tables\dimension.date_dim.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Tables\dimension.team_dim.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Tables\dimension.player_dim.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Tables\fact.game_fact.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Tables\fact.player_game_stats_fact.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Tables\staging.game_raw.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Tables\staging.player_raw.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Tables\staging.player_game_stats_raw.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Tables\staging.team_raw.sql"

-- Create stored procedures
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Stored Procedures\audit.P_START_LOAD_BATCH.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Stored Procedures\audit.P_END_LOAD_BATCH.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Stored Procedures\dimension.P_LOAD_DIM_TEAM.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Stored Procedures\dimension.P_LOAD_DIM_PLAYER.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Stored Procedures\dimension.P_POPULATE_DATE_DIMENSION.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Stored Procedures\fact.P_LOAD_FACT_GAME.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Stored Procedures\fact.P_LOAD_FACT_PLAYER_GAME_STATS.sql"

-- Create reporting views
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Views\reporting.V_TEAM_GAME_RESULTS.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Views\reporting.V_PLAYER_GAME_STATS.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Views\reporting.V_TEAM_SEASON_SUMMARY.sql"
:r "C:\Workspace\NHLDataWarehouse\Database\Objects\Views\reporting.V_PLAYER_SEASON_SUMMARY.sql"

-- Optional sample data
-- :r ".\004_LoadSampleData.sql"
