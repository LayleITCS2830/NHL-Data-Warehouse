USE NHLDataWarehouse;
GO

IF OBJECT_ID('Fact.PlayerGameStats', 'U') IS NULL
BEGIN
    CREATE TABLE Fact.PlayerGameStats
    (
        PlayerGameStatsKey BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Fact_PlayerGameStats PRIMARY KEY,
        GameKey BIGINT NOT NULL,
        PlayerKey INT NOT NULL,
        TeamKey INT NOT NULL,
        Goals INT NOT NULL CONSTRAINT DF_Fact_PlayerGameStats_Goals DEFAULT (0),
        Assists INT NOT NULL CONSTRAINT DF_Fact_PlayerGameStats_Assists DEFAULT (0),
        Points AS (Goals + Assists) PERSISTED,
        Shots INT NOT NULL CONSTRAINT DF_Fact_PlayerGameStats_Shots DEFAULT (0),
        Hits INT NOT NULL CONSTRAINT DF_Fact_PlayerGameStats_Hits DEFAULT (0),
        Blocks INT NOT NULL CONSTRAINT DF_Fact_PlayerGameStats_Blocks DEFAULT (0),
        PenaltyMinutes INT NOT NULL CONSTRAINT DF_Fact_PlayerGameStats_PenaltyMinutes DEFAULT (0),
        TimeOnIceSeconds INT NULL,
        CreatedDate DATETIME2 NOT NULL CONSTRAINT DF_Fact_PlayerGameStats_CreatedDate DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT UQ_Fact_PlayerGameStats_Game_Player UNIQUE (GameKey, PlayerKey),
        CONSTRAINT FK_Fact_PlayerGameStats_Game FOREIGN KEY (GameKey) REFERENCES Fact.Game (GameKey),
        CONSTRAINT FK_Fact_PlayerGameStats_Player FOREIGN KEY (PlayerKey) REFERENCES Dimension.Player (PlayerKey),
        CONSTRAINT FK_Fact_PlayerGameStats_Team FOREIGN KEY (TeamKey) REFERENCES Dimension.Team (TeamKey)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Fact_PlayerGameStats_PlayerKey' AND object_id = OBJECT_ID('Fact.PlayerGameStats'))
    CREATE NONCLUSTERED INDEX IX_Fact_PlayerGameStats_PlayerKey ON Fact.PlayerGameStats (PlayerKey);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Fact_PlayerGameStats_TeamKey' AND object_id = OBJECT_ID('Fact.PlayerGameStats'))
    CREATE NONCLUSTERED INDEX IX_Fact_PlayerGameStats_TeamKey ON Fact.PlayerGameStats (TeamKey);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Fact_PlayerGameStats_GameKey' AND object_id = OBJECT_ID('Fact.PlayerGameStats'))
    CREATE NONCLUSTERED INDEX IX_Fact_PlayerGameStats_GameKey ON Fact.PlayerGameStats (GameKey);
GO
