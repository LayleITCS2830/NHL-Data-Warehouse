USE NHLDataWarehouse;
GO

IF OBJECT_ID('Staging.PlayerRaw', 'U') IS NULL
BEGIN
    CREATE TABLE Staging.PlayerRaw
    (
        RawID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Staging_PlayerRaw PRIMARY KEY,
        SourceSystem VARCHAR(50) NOT NULL CONSTRAINT DF_Staging_PlayerRaw_SourceSystem DEFAULT ('NHL API'),
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
        CreatedDate DATETIME2 NOT NULL CONSTRAINT DF_Staging_PlayerRaw_CreatedDate DEFAULT (SYSUTCDATETIME())
    );
END
GO
