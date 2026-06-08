USE NHLDataWarehouse;
GO

CREATE OR ALTER PROCEDURE Dimension.usp_PopulateDateDimension
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SET NOCOUNT ON;

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
    INSERT INTO Dimension.[Date]
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
        FROM Dimension.[Date] AS tgt
        WHERE tgt.FullDate = d.FullDate
    )
    OPTION (MAXRECURSION 32767);
END
GO
