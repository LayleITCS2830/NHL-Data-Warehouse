USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE Audit.usp_EndLoadBatch
    @LoadBatchID UNIQUEIDENTIFIER,
    @Status VARCHAR(20),
    @RowsInserted INT = NULL,
    @RowsUpdated INT = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Audit.LoadBatch
    SET LoadEndDate = SYSUTCDATETIME(),
        Status = @Status,
        RowsInserted = @RowsInserted,
        RowsUpdated = @RowsUpdated,
        ErrorMessage = @ErrorMessage
    WHERE LoadBatchID = @LoadBatchID;
END
GO
