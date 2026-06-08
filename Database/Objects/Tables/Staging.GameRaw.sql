USE NHLDataWarehouse;
GO

IF OBJECT_ID('Staging.GameRaw', 'U') IS NULL
BEGIN
    CREATE TABLE Staging.GameRaw
    (
        RawID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Staging_GameRaw PRIMARY KEY,
        SourceSystem VARCHAR(50) NOT NULL CONSTRAINT DF_Staging_GameRaw_SourceSystem DEFAULT ('NHL API'),
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
        CreatedDate DATETIME2 NOT NULL CONSTRAINT DF_Staging_GameRaw_CreatedDate DEFAULT (SYSUTCDATETIME())
    );
END
GO
