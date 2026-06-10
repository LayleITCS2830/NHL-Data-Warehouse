/*
    Loads all sample data through the warehouse ETL load procedures.
    Run this script from the Database folder in SQLCMD mode.
*/
:on error exit

-- Start from a clean sample-data state.
:r ".\Objects\SampleData\002_CleanupSampleData.sql"

-- Stage sample rows.
:r ".\Objects\SampleData\001_InsertSampleData.sql"

-- Execute load procedures in dependency order.
:r ".\Objects\SampleData\003_ExecuteSampleLoadProcedures.sql"
