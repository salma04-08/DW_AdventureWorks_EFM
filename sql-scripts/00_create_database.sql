USE master;
GO

-- Ferme toutes les connexions actives
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'DW_SalesPerformance_AW')
BEGIN
    ALTER DATABASE DW_SalesPerformance_AW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DW_SalesPerformance_AW;
END
GO

CREATE DATABASE DW_SalesPerformance_AW;
GO

USE DW_SalesPerformance_AW;
GO

CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO

PRINT '✓ Base DW_SalesPerformance_AW créée avec les schémas Bronze / Silver / Gold';

