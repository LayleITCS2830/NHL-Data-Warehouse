USE NHLDataWarehouse;
GO

IF OBJECT_ID('Dimension.[Date]', 'U') IS NULL
BEGIN
    CREATE TABLE Dimension.[Date]
    (
        DateKey INT NOT NULL CONSTRAINT PK_Dimension_Date PRIMARY KEY,
        FullDate DATE NOT NULL,
        CalendarYear SMALLINT NOT NULL,
        CalendarQuarter TINYINT NOT NULL,
        CalendarMonth TINYINT NOT NULL,
        MonthName VARCHAR(20) NOT NULL,
        DayOfMonth TINYINT NOT NULL,
        DayOfWeek TINYINT NOT NULL,
        DayName VARCHAR(20) NOT NULL,
        IsWeekend BIT NOT NULL,
        CONSTRAINT UQ_Dimension_Date_FullDate UNIQUE (FullDate)
    );
END
GO
