USE NHLDataWarehouse;
GO

IF OBJECT_ID('staging.GAME_RAW', 'U') IS NULL
BEGIN
    CREATE TABLE staging.GAME_RAW
    (
        RawID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT GAME_RAW_pk PRIMARY KEY,
        SourceSystem VARCHAR(50) NOT NULL CONSTRAINT GAME_RAW_SourceSystem_df DEFAULT ('NHL API'),
        LoadBatchID UNIQUEIDENTIFIER NOT NULL,
        RawJson NVARCHAR(MAX) NULL,
        GameID BIGINT NULL,
        GameDate DATE NULL,
        Season VARCHAR(10) NULL,
        GameType VARCHAR(20) NULL,
        HomeTeamID INT NULL,
        AwayTeamID INT NULL,
        HomeGoals INT NULL,
        AwayGoals INT NULL,
        HomeShots INT NULL,
        AwayShots INT NULL,
        CreatedDate DATETIME2 NOT NULL CONSTRAINT GAME_RAW_CreatedDate_df DEFAULT (SYSUTCDATETIME())
    );
END
GO
