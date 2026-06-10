USE NHLDataWarehouse;
GO

IF OBJECT_ID('staging.PLAYER_RAW', 'U') IS NULL
BEGIN
    CREATE TABLE staging.PLAYER_RAW
    (
        RawID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PLAYER_RAW_pk PRIMARY KEY,
        SourceSystem VARCHAR(50) NOT NULL CONSTRAINT PLAYER_RAW_SourceSystem_df DEFAULT ('NHL API'),
        LoadBatchID UNIQUEIDENTIFIER NOT NULL,
        RawJson NVARCHAR(MAX) NULL,
        PlayerID INT NULL,
        TeamID INT NULL,
        FirstName VARCHAR(100) NULL,
        LastName VARCHAR(100) NULL,
        FullName VARCHAR(200) NULL,
        PositionCode VARCHAR(10) NULL,
        ShootsCatches VARCHAR(10) NULL,
        BirthDate DATE NULL,
        CreatedDate DATETIME2 NOT NULL CONSTRAINT PLAYER_RAW_CreatedDate_df DEFAULT (SYSUTCDATETIME())
    );
END
GO
