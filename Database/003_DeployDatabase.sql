/*
    Deploys the NHLDataWarehouse database.
    Run this script from the Database folder in SQLCMD mode.
*/
:on error exit

-- Create database and schemas
:r .\001_CreateDatabase.sql
:r .\002_CreateSchemas.sql

-- Create tables
:r ".\Objects\Tables\Audit.LoadBatch.sql"
:r ".\Objects\Tables\Dimension.Date.sql"
:r ".\Objects\Tables\Dimension.Team.sql"
:r ".\Objects\Tables\Dimension.Player.sql"
:r ".\Objects\Tables\Fact.Game.sql"
:r ".\Objects\Tables\Fact.PlayerGameStats.sql"
:r ".\Objects\Tables\Staging.GameRaw.sql"
:r ".\Objects\Tables\Staging.PlayerRaw.sql"
:r ".\Objects\Tables\Staging.PlayerGameStatsRaw.sql"
:r ".\Objects\Tables\Staging.TeamRaw.sql"

-- Create stored procedures
:r ".\Objects\Stored Procedures\Audit.usp_StartLoadBatch.sql"
:r ".\Objects\Stored Procedures\Audit.usp_EndLoadBatch.sql"
:r ".\Objects\Stored Procedures\Dimension.usp_LoadDimTeam.sql"
:r ".\Objects\Stored Procedures\Dimension.usp_LoadDimPlayer.sql"
:r ".\Objects\Stored Procedures\Dimension.usp_PopulateDateDimension.sql"
:r ".\Objects\Stored Procedures\Fact.usp_LoadFactGame.sql"
:r ".\Objects\Stored Procedures\Fact.usp_LoadFactPlayerGameStats.sql"

-- Create reporting views
:r ".\Objects\Views\Reporting.vwTeamGameResults.sql"
:r ".\Objects\Views\Reporting.vwPlayerGameStats.sql"
:r ".\Objects\Views\Reporting.vwTeamSeasonSummary.sql"
:r ".\Objects\Views\Reporting.vwPlayerSeasonSummary.sql"

-- Optional sample data
-- :r ".\Objects\SampleData\001_InsertSampleData.sql"
