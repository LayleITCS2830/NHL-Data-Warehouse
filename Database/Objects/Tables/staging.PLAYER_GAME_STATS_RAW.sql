USE NHLDataWarehouse;
GO

IF OBJECT_ID('staging.PLAYER_GAME_STATS_RAW', 'U') IS NULL
BEGIN
    CREATE TABLE staging.PLAYER_GAME_STATS_RAW
    (
        RawID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PLAYER_GAME_STATS_RAW_pk PRIMARY KEY,
        SourceSystem VARCHAR(50) NOT NULL CONSTRAINT PLAYER_GAME_STATS_RAW_SourceSystem_df DEFAULT ('NHL API'),
        LoadBatchID UNIQUEIDENTIFIER NOT NULL,
        RawJson NVARCHAR(MAX) NULL,
        GameID BIGINT NULL,
        PlayerID INT NULL,
        TeamID INT NULL,
        Goals INT NULL,
        Assists INT NULL,
        Shots INT NULL,
        Hits INT NULL,
        Blocks INT NULL,
        PenaltyMinutes INT NULL,
        TimeOnIceSeconds INT NULL,
        CreatedDate DATETIME2 NOT NULL CONSTRAINT PLAYER_GAME_STATS_RAW_CreatedDate_df DEFAULT (SYSUTCDATETIME())
    );
END
GO
