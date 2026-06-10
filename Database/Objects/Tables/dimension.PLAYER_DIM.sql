USE NHLDataWarehouse;
GO

IF OBJECT_ID('dimension.PLAYER_DIM', 'U') IS NULL
BEGIN
    CREATE TABLE dimension.PLAYER_DIM
    (
        PlayerKey INT IDENTITY(1,1) NOT NULL CONSTRAINT PLAYER_DIM_pk PRIMARY KEY,
        PlayerID INT NOT NULL,
        TeamKey INT NULL,
        FirstName VARCHAR(100) NULL,
        LastName VARCHAR(100) NULL,
        FullName VARCHAR(200) NOT NULL,
        PositionCode VARCHAR(10) NULL,
        ShootsCatches VARCHAR(10) NULL,
        BirthDate DATE NULL,
        IsActive BIT NOT NULL CONSTRAINT PLAYER_DIM_IsActive_df DEFAULT (1),
        CreatedDate DATETIME2 NOT NULL CONSTRAINT PLAYER_DIM_CreatedDate_df DEFAULT (SYSUTCDATETIME()),
        ModifiedDate DATETIME2 NULL,
        CONSTRAINT PLAYER_DIM_PlayerID_uq UNIQUE (PlayerID),
        CONSTRAINT TEAM_DIM_PLAYER_DIM_fk FOREIGN KEY (TeamKey) REFERENCES dimension.TEAM_DIM (TeamKey)
    );
END
GO
