USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE audit.P_START_LOAD_BATCH
    @source_system VARCHAR(50) = 'NHL API',
    @load_batch_id UNIQUEIDENTIFIER OUTPUT
AS
/*****************************************************************************************
PROC:	audit.P_START_LOAD_BATCH
AUTHOR:	Andrew Layle
DATE:	06/09/2026

DESCRIPTION:
    Initializes a new load batch for audit tracking and logging purposes. Generates a
    unique load_batch_id and creates a new record in audit.load_batch with a Started status.

INPUT PARAMETERS:
    @source_system VARCHAR(50) - The source system identifier. Default: 'NHL API'

OUTPUT PARAMETERS:
    @load_batch_id UNIQUEIDENTIFIER - The unique identifier for this load batch.

*****************************************************************************************/

SET NOCOUNT ON
SET XACT_ABORT ON

SET @load_batch_id = NEWID();

INSERT INTO audit.load_batch (load_batch_id, source_system, status)
VALUES (@load_batch_id, @source_system, 'Started')

GO
