USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE Audit.usp_StartLoadBatch
    @SourceSystem VARCHAR(50) = 'NHL API',
    @LoadBatchID UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SET @LoadBatchID = NEWID();

    INSERT INTO Audit.LoadBatch (LoadBatchID, SourceSystem, Status)
    VALUES (@LoadBatchID, @SourceSystem, 'Started');
END
GO
