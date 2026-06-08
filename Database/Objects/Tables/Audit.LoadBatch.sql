USE NHLDataWarehouse;
GO

IF OBJECT_ID('Audit.LoadBatch', 'U') IS NULL
BEGIN
    CREATE TABLE Audit.LoadBatch
    (
        LoadBatchID UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Audit_LoadBatch PRIMARY KEY,
        SourceSystem VARCHAR(50) NOT NULL,
        LoadStartDate DATETIME2 NOT NULL CONSTRAINT DF_Audit_LoadBatch_LoadStartDate DEFAULT (SYSUTCDATETIME()),
        LoadEndDate DATETIME2 NULL,
        Status VARCHAR(20) NOT NULL,
        RowsInserted INT NULL,
        RowsUpdated INT NULL,
        ErrorMessage NVARCHAR(MAX) NULL
    );
END
GO
