USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE dimension.P_POPULATE_DATE_DIMENSION
    @StartDate DATE,
    @EndDate DATE
AS
/*****************************************************************************************
PROC:	dimension.P_POPULATE_DATE_DIMENSION
AUTHOR:	Andrew Layle
DATE:	06/09/2026

DESCRIPTION:
    Populates dimension.date_dim with calendar attributes for each date in the requested
    range. Existing dates are skipped so the procedure is rerunnable.

INPUT PARAMETERS:
    @StartDate DATE - The first date to populate.
    @EndDate DATE - The final date to populate.

*****************************************************************************************/

SET NOCOUNT ON
SET XACT_ABORT ON

IF @StartDate IS NULL OR @EndDate IS NULL OR @StartDate > @EndDate
    THROW 50001, 'Provide a valid start and end date.', 1

;WITH dates AS
(
    SELECT  @StartDate AS full_date
    UNION ALL
    SELECT  DATEADD(DAY, 1, full_date)
    FROM    dates
    WHERE   full_date < @EndDate
)
INSERT INTO dimension.date_dim
        (date_key, full_date, calendar_year, calendar_quarter, calendar_month, month_name, day_of_month, day_of_week, day_name, is_weekend)
SELECT CONVERT(INT, FORMAT(full_date, 'yyyyMMdd')),
        full_date,
        DATEPART(YEAR, full_date),
        DATEPART(QUARTER, full_date),
        DATEPART(MONTH, full_date),
        DATENAME(MONTH, full_date),
        DATEPART(DAY, full_date),
        DATEPART(WEEKDAY, full_date),
        DATENAME(WEEKDAY, full_date),
        CASE WHEN DATENAME(WEEKDAY, full_date) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END
FROM    dates       d
WHERE   NOT EXISTS  (
                        SELECT 1
                        FROM dimension.date_dim AS tgt
                        WHERE tgt.full_date = d.full_date
                    )
OPTION (MAXRECURSION 32767)

GO
