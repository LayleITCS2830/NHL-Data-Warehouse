USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE audit.P_START_LOAD_BATCH
    @SourceSystem VARCHAR(50) = 'NHL API',
    @LoadBatchID UNIQUEIDENTIFIER OUTPUT
AS
/*****************************************************************************************
PROC:	audit.P_START_LOAD_BATCH
AUTHOR:	Andrew Layle
DATE:	06/09/2026

DESCRIPTION:
    Initializes a new load batch for audit tracking and logging purposes. Generates a
    unique LoadBatchID and creates a new record in audit.LOAD_BATCH with a Started status.

INPUT PARAMETERS:
    @SourceSystem VARCHAR(50) - The source system identifier. Default: 'NHL API'

OUTPUT PARAMETERS:
    @LoadBatchID UNIQUEIDENTIFIER - The unique identifier for this load batch.

*****************************************************************************************/
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @LoadBatchID = NEWID();

    INSERT INTO audit.LOAD_BATCH (LoadBatchID, SourceSystem, Status)
    VALUES (@LoadBatchID, @SourceSystem, 'Started');
END
GO
