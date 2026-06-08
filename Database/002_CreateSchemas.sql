USE NHLDataWarehouse;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Staging')
    EXEC('CREATE SCHEMA Staging');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Dimension')
    EXEC('CREATE SCHEMA Dimension');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Fact')
    EXEC('CREATE SCHEMA Fact');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Reporting')
    EXEC('CREATE SCHEMA Reporting');
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Audit')
    EXEC('CREATE SCHEMA Audit');
GO
