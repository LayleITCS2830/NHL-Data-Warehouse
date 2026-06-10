USE NHLDataWarehouse;
GO

IF OBJECT_ID('dimension.DATE_DIM', 'U') IS NULL
BEGIN
    CREATE TABLE dimension.DATE_DIM
    (
        DateKey INT NOT NULL CONSTRAINT DATE_DIM_pk PRIMARY KEY,
        FullDate DATE NOT NULL,
        CalendarYear SMALLINT NOT NULL,
        CalendarQuarter TINYINT NOT NULL,
        CalendarMonth TINYINT NOT NULL,
        MonthName VARCHAR(20) NOT NULL,
        DayOfMonth TINYINT NOT NULL,
        DayOfWeek TINYINT NOT NULL,
        DayName VARCHAR(20) NOT NULL,
        IsWeekend BIT NOT NULL,
        CONSTRAINT DATE_DIM_FullDate_uq UNIQUE (FullDate)
    );
END
GO
