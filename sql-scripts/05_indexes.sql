-- ============================================================
-- 05_indexes.sql
-- Optimisation des performances — Index columnstore + Index B-Tree
-- Différenciateur fort : montre la maîtrise de l'optimisation
-- ============================================================

USE DW_SalesPerformance_AW;
GO

-- ============================================================
-- INDEX COLUMNSTORE — FactSales
-- Optimisé pour les requêtes analytiques (SUM, AVG, GROUP BY)
-- Gain de performance : 10x à 100x sur les agrégations
-- ============================================================
CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_FactSales
ON gold.FactSales (
    DateKey,
    ProductKey,
    CustomerKey,
    TerritoryKey,
    SalesPersonKey,
    OrderQuantity,
    SalesAmount,
    TotalCost,
    Profit,
    Discount
);
GO
PRINT '✓ Index columnstore NCCI_FactSales créé';

-- ============================================================
-- INDEX B-TREE — FactSales (requêtes filtrées fréquentes)
-- ============================================================

-- Filtre par date (tendances temporelles)
CREATE NONCLUSTERED INDEX IX_FactSales_DateKey
ON gold.FactSales (DateKey)
INCLUDE (SalesAmount, Profit, OrderQuantity);
GO
PRINT '✓ Index IX_FactSales_DateKey créé';

-- Filtre par territoire (analyse géographique)
CREATE NONCLUSTERED INDEX IX_FactSales_TerritoryKey
ON gold.FactSales (TerritoryKey)
INCLUDE (SalesAmount, Profit, OrderQuantity);
GO
PRINT '✓ Index IX_FactSales_TerritoryKey créé';

-- Filtre par produit (analyse produits)
CREATE NONCLUSTERED INDEX IX_FactSales_ProductKey
ON gold.FactSales (ProductKey)
INCLUDE (SalesAmount, Profit, OrderQuantity);
GO
PRINT '✓ Index IX_FactSales_ProductKey créé';

-- Filtre par vendeur (performance commerciale)
CREATE NONCLUSTERED INDEX IX_FactSales_SalesPersonKey
ON gold.FactSales (SalesPersonKey)
INCLUDE (SalesAmount, Profit, OrderQuantity);
GO
PRINT '✓ Index IX_FactSales_SalesPersonKey créé';

-- ============================================================
-- INDEX B-TREE — DimProduct (SCD Type 2)
-- Accélère le Lookup SCD2 dans SSIS et les requêtes Gold
-- ============================================================
CREATE NONCLUSTERED INDEX IX_DimProduct_ProductID_Current
ON gold.DimProduct (ProductID, IsCurrent)
INCLUDE (ProductName, CategoryName, SubcategoryName, StandardCost, ListPrice);
GO
PRINT '✓ Index IX_DimProduct_ProductID_Current créé';

CREATE NONCLUSTERED INDEX IX_DimProduct_Dates
ON gold.DimProduct (ProductID, DWStartDate, DWEndDate);
GO
PRINT '✓ Index IX_DimProduct_Dates créé';

-- ============================================================
-- INDEX B-TREE — DimCustomer
-- ============================================================
CREATE NONCLUSTERED INDEX IX_DimCustomer_CustomerID
ON gold.DimCustomer (CustomerID)
INCLUDE (FullName, CustomerType, TerritoryID);
GO
PRINT '✓ Index IX_DimCustomer_CustomerID créé';

-- ============================================================
-- INDEX B-TREE — DimDate (hiérarchie temporelle)
-- ============================================================
CREATE NONCLUSTERED INDEX IX_DimDate_YearMonth
ON gold.DimDate (Year, Month, DateKey)
INCLUDE (Quarter, MonthName, QuarterName);
GO
PRINT '✓ Index IX_DimDate_YearMonth créé';

-- ============================================================
-- VÉRIFICATION — liste tous les index créés
-- ============================================================
SELECT
    t.name                          AS TableName,
    i.name                          AS IndexName,
    i.type_desc                     AS IndexType,
    i.is_primary_key                AS IsPrimaryKey
FROM sys.indexes i
JOIN sys.tables  t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'gold'
  AND i.name IS NOT NULL
ORDER BY t.name, i.type_desc DESC;
GO

PRINT '';
PRINT '══════════════════════════════════════════════════════════════';
PRINT '✓ INDEXES complets — FactSales + toutes dimensions optimisées';
PRINT '══════════════════════════════════════════════════════════════';