USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE audit.P_END_LOAD_BATCH
    @LoadBatchID UNIQUEIDENTIFIER,
    @Status VARCHAR(20),
    @RowsInserted INT = NULL,
    @RowsUpdated INT = NULL,
    @ErrorMessage NVARCHAR(MAX) = NULL
AS
/*****************************************************************************************
PROC:	audit.P_END_LOAD_BATCH
AUTHOR:	Andrew Layle
DATE:	06/09/2026

DESCRIPTION:
    Completes a load batch by recording the end timestamp, final status, load statistics,
    and error details when a load fails.

INPUT PARAMETERS:
    @LoadBatchID UNIQUEIDENTIFIER - The identifier for the load batch to complete.
    @Status VARCHAR(20) - Final status: 'Succeeded' or 'Failed'.
    @RowsInserted INT - Number of rows inserted during the load. Default: NULL
    @RowsUpdated INT - Number of rows updated during the load. Default: NULL
    @ErrorMessage NVARCHAR(MAX) - Error message if the load failed. Default: NULL

*****************************************************************************************/
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    UPDATE audit.LOAD_BATCH
    SET LoadEndDate = SYSUTCDATETIME(),
        Status = @Status,
        RowsInserted = @RowsInserted,
        RowsUpdated = @RowsUpdated,
        ErrorMessage = @ErrorMessage
    WHERE LoadBatchID = @LoadBatchID;
END
GO
