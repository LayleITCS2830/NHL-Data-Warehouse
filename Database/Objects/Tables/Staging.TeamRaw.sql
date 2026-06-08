USE NHLDataWarehouse;
GO

IF OBJECT_ID('Staging.TeamRaw', 'U') IS NULL
BEGIN
    CREATE TABLE Staging.TeamRaw
    (
        RawID BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Staging_TeamRaw PRIMARY KEY,
        SourceSystem VARCHAR(50) NOT NULL CONSTRAINT DF_Staging_TeamRaw_SourceSystem DEFAULT ('NHL API'),
        LoadBatchID UNIQUEIDENTIFIER NOT NULL,
        RawJson NVARCHAR(MAX) NULL,
        TeamID INT NULL,
        TeamName VARCHAR(100) NULL,
        TeamAbbreviation VARCHAR(10) NULL,
        Conference VARCHAR(50) NULL,
        Division VARCHAR(50) NULL,
        CreatedDate DATETIME2 NOT NULL CONSTRAINT DF_Staging_TeamRaw_CreatedDate DEFAULT (SYSUTCDATETIME())
    );
END
GO
