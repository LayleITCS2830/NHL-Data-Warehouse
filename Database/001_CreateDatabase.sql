/*
    Creates the NHLDataWarehouse database with SQL Server 2022 compatibility.
    This script is portable and does not reference local file paths.
*/
IF DB_ID('NHLDataWarehouse') IS NULL
BEGIN
    CREATE DATABASE NHLDataWarehouse;
END
GO

ALTER DATABASE NHLDataWarehouse SET COMPATIBILITY_LEVEL = 160;
GO

USE NHLDataWarehouse;
GO
