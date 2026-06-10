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
    Populates dimension.DATE_DIM with calendar attributes for each date in the requested
    range. Existing dates are skipped so the procedure is rerunnable.

INPUT PARAMETERS:
    @StartDate DATE - The first date to populate.
    @EndDate DATE - The final date to populate.

*****************************************************************************************/
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @StartDate IS NULL OR @EndDate IS NULL OR @StartDate > @EndDate
        THROW 50001, 'Provide a valid start and end date.', 1;

    ;WITH Dates AS
    (
        SELECT @StartDate AS FullDate
        UNION ALL
        SELECT DATEADD(DAY, 1, FullDate)
        FROM Dates
        WHERE FullDate < @EndDate
    )
    INSERT INTO dimension.DATE_DIM
        (DateKey, FullDate, CalendarYear, CalendarQuarter, CalendarMonth, MonthName, DayOfMonth, DayOfWeek, DayName, IsWeekend)
    SELECT CONVERT(INT, FORMAT(FullDate, 'yyyyMMdd')),
           FullDate,
           DATEPART(YEAR, FullDate),
           DATEPART(QUARTER, FullDate),
           DATEPART(MONTH, FullDate),
           DATENAME(MONTH, FullDate),
           DATEPART(DAY, FullDate),
           DATEPART(WEEKDAY, FullDate),
           DATENAME(WEEKDAY, FullDate),
           CASE WHEN DATENAME(WEEKDAY, FullDate) IN ('Saturday', 'Sunday') THEN 1 ELSE 0 END
    FROM Dates AS d
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM dimension.DATE_DIM AS tgt
        WHERE tgt.FullDate = d.FullDate
    )
    OPTION (MAXRECURSION 32767);
END
GO
