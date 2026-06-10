USE NHLDataWarehouse;
GO

IF OBJECT_ID('audit.LOAD_BATCH', 'U') IS NULL
BEGIN
    CREATE TABLE audit.LOAD_BATCH
    (
        LoadBatchID UNIQUEIDENTIFIER NOT NULL CONSTRAINT LOAD_BATCH_pk PRIMARY KEY,
        SourceSystem VARCHAR(50) NOT NULL,
        LoadStartDate DATETIME2 NOT NULL CONSTRAINT LOAD_BATCH_LoadStartDate_df DEFAULT (SYSUTCDATETIME()),
        LoadEndDate DATETIME2 NULL,
        Status VARCHAR(20) NOT NULL,
        RowsInserted INT NULL,
        RowsUpdated INT NULL,
        ErrorMessage NVARCHAR(MAX) NULL
    );
END
GO
