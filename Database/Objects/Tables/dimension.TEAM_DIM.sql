USE NHLDataWarehouse;
GO

IF OBJECT_ID('dimension.TEAM_DIM', 'U') IS NULL
BEGIN
    CREATE TABLE dimension.TEAM_DIM
    (
        TeamKey INT IDENTITY(1,1) NOT NULL CONSTRAINT TEAM_DIM_pk PRIMARY KEY,
        TeamID INT NOT NULL,
        TeamName VARCHAR(100) NOT NULL,
        TeamAbbreviation VARCHAR(10) NULL,
        Conference VARCHAR(50) NULL,
        Division VARCHAR(50) NULL,
        IsActive BIT NOT NULL CONSTRAINT TEAM_DIM_IsActive_df DEFAULT (1),
        CreatedDate DATETIME2 NOT NULL CONSTRAINT TEAM_DIM_CreatedDate_df DEFAULT (SYSUTCDATETIME()),
        ModifiedDate DATETIME2 NULL,
        CONSTRAINT TEAM_DIM_TeamID_uq UNIQUE (TeamID)
    );
END
GO
