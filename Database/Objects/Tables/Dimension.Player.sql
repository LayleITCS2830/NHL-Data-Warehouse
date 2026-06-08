USE NHLDataWarehouse;
GO

IF OBJECT_ID('Dimension.Player', 'U') IS NULL
BEGIN
    CREATE TABLE Dimension.Player
    (
        PlayerKey INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Dimension_Player PRIMARY KEY,
        PlayerID INT NOT NULL,
        TeamKey INT NULL,
        FirstName VARCHAR(100) NULL,
        LastName VARCHAR(100) NULL,
        FullName VARCHAR(200) NOT NULL,
        PositionCode VARCHAR(10) NULL,
        ShootsCatches VARCHAR(10) NULL,
        BirthDate DATE NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_Dimension_Player_IsActive DEFAULT (1),
        CreatedDate DATETIME2 NOT NULL CONSTRAINT DF_Dimension_Player_CreatedDate DEFAULT (SYSUTCDATETIME()),
        ModifiedDate DATETIME2 NULL,
        CONSTRAINT UQ_Dimension_Player_PlayerID UNIQUE (PlayerID),
        CONSTRAINT FK_Dimension_Player_Team FOREIGN KEY (TeamKey) REFERENCES Dimension.Team (TeamKey)
    );
END
GO
