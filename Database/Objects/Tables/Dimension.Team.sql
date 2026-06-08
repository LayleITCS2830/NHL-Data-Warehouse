USE NHLDataWarehouse;
GO

IF OBJECT_ID('Dimension.Team', 'U') IS NULL
BEGIN
    CREATE TABLE Dimension.Team
    (
        TeamKey INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_Dimension_Team PRIMARY KEY,
        TeamID INT NOT NULL,
        TeamName VARCHAR(100) NOT NULL,
        TeamAbbreviation VARCHAR(10) NULL,
        Conference VARCHAR(50) NULL,
        Division VARCHAR(50) NULL,
        IsActive BIT NOT NULL CONSTRAINT DF_Dimension_Team_IsActive DEFAULT (1),
        CreatedDate DATETIME2 NOT NULL CONSTRAINT DF_Dimension_Team_CreatedDate DEFAULT (SYSUTCDATETIME()),
        ModifiedDate DATETIME2 NULL,
        CONSTRAINT UQ_Dimension_Team_TeamID UNIQUE (TeamID)
    );
END
GO
