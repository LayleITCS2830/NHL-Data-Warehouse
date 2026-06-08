USE NHLDataWarehouse;
GO

IF OBJECT_ID('Fact.Game', 'U') IS NULL
BEGIN
    CREATE TABLE Fact.Game
    (
        GameKey BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Fact_Game PRIMARY KEY,
        GameID BIGINT NOT NULL,
        DateKey INT NOT NULL,
        Season VARCHAR(10) NULL,
        GameType VARCHAR(20) NULL,
        HomeTeamKey INT NOT NULL,
        AwayTeamKey INT NOT NULL,
        HomeGoals INT NULL,
        AwayGoals INT NULL,
        HomeShots INT NULL,
        AwayShots INT NULL,
        CreatedDate DATETIME2 NOT NULL CONSTRAINT DF_Fact_Game_CreatedDate DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT UQ_Fact_Game_GameID UNIQUE (GameID),
        CONSTRAINT FK_Fact_Game_Date FOREIGN KEY (DateKey) REFERENCES Dimension.[Date] (DateKey),
        CONSTRAINT FK_Fact_Game_HomeTeam FOREIGN KEY (HomeTeamKey) REFERENCES Dimension.Team (TeamKey),
        CONSTRAINT FK_Fact_Game_AwayTeam FOREIGN KEY (AwayTeamKey) REFERENCES Dimension.Team (TeamKey)
    );
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Fact_Game_DateKey' AND object_id = OBJECT_ID('Fact.Game'))
    CREATE NONCLUSTERED INDEX IX_Fact_Game_DateKey ON Fact.Game (DateKey);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Fact_Game_HomeTeamKey' AND object_id = OBJECT_ID('Fact.Game'))
    CREATE NONCLUSTERED INDEX IX_Fact_Game_HomeTeamKey ON Fact.Game (HomeTeamKey);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Fact_Game_AwayTeamKey' AND object_id = OBJECT_ID('Fact.Game'))
    CREATE NONCLUSTERED INDEX IX_Fact_Game_AwayTeamKey ON Fact.Game (AwayTeamKey);
GO
