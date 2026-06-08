USE NHLDataWarehouse;
GO

IF OBJECT_ID('Staging.PlayerGameStatsRaw', 'U') IS NULL
BEGIN
    CREATE TABLE Staging.PlayerGameStatsRaw
    (
        RawID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Staging_PlayerGameStatsRaw PRIMARY KEY,
        SourceSystem VARCHAR(50) NOT NULL CONSTRAINT DF_Staging_PlayerGameStatsRaw_SourceSystem DEFAULT ('NHL API'),
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
        CreatedDate DATETIME2 NOT NULL CONSTRAINT DF_Staging_PlayerGameStatsRaw_CreatedDate DEFAULT (SYSUTCDATETIME())
    );
END
GO
