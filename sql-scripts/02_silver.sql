-- ============================================================
-- 02_silver.sql
-- Nettoyage, transformation et enrichissement des données
-- Bronze → Silver : jointures, nulls, calculs métier
-- ============================================================

USE DW_SalesPerformance_AW;
GO

-- ------------------------------------------------------------
-- Nettoyage
-- ------------------------------------------------------------
IF OBJECT_ID('silver.CleanSales')               IS NOT NULL DROP TABLE silver.CleanSales;
IF OBJECT_ID('silver.CleanProduct')             IS NOT NULL DROP TABLE silver.CleanProduct;
IF OBJECT_ID('silver.CleanCustomer')            IS NOT NULL DROP TABLE silver.CleanCustomer;
IF OBJECT_ID('silver.CleanTerritory')           IS NOT NULL DROP TABLE silver.CleanTerritory;
IF OBJECT_ID('silver.CleanSalesPerson')         IS NOT NULL DROP TABLE silver.CleanSalesPerson;
IF OBJECT_ID('silver.CleanProductCostHistory')  IS NOT NULL DROP TABLE silver.CleanProductCostHistory;
IF OBJECT_ID('silver.CleanProductPriceHistory') IS NOT NULL DROP TABLE silver.CleanProductPriceHistory;
GO

-- ------------------------------------------------------------
-- TABLE 1 — CleanSales
-- ------------------------------------------------------------
SELECT
    soh.SalesOrderID,
    sod.SalesOrderDetailID,
    CAST(soh.OrderDate AS DATE)                               AS OrderDate,
    CAST(soh.DueDate   AS DATE)                               AS DueDate,
    CAST(soh.ShipDate  AS DATE)                               AS ShipDate,
    soh.CustomerID,
    ISNULL(soh.SalesPersonID, -1)                             AS SalesPersonID,
    soh.TerritoryID,
    sod.ProductID,
    sod.OrderQty                                              AS OrderQuantity,
    sod.UnitPrice,
    ISNULL(sod.UnitPriceDiscount, 0)                          AS Discount,
    ROUND(sod.LineTotal, 2)                                   AS SalesAmount,
    ROUND(sod.OrderQty * p.StandardCost, 2)                   AS TotalCost,
    ROUND(sod.LineTotal - (sod.OrderQty * p.StandardCost), 2) AS Profit,
    soh.OnlineOrderFlag
INTO silver.CleanSales
FROM bronze.SalesOrderHeader soh
JOIN bronze.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN bronze.Product          p   ON sod.ProductID    = p.ProductID
WHERE soh.Status = 5
  AND sod.UnitPrice  > 0
  AND p.StandardCost > 0;

PRINT '✓ silver.CleanSales — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 2 — CleanProduct
-- SellEndDate : on garde NULL tel quel sans CAST problématique
-- ------------------------------------------------------------
SELECT DISTINCT
    p.ProductID,
    p.Name                                                    AS ProductName,
    p.ProductNumber,
    ISNULL(sc.Name, 'Sans catégorie')                         AS SubcategoryName,
    ISNULL(c.Name,  'Sans catégorie')                         AS CategoryName,
    ISNULL(p.Color, 'Non défini')                             AS Color,
    p.StandardCost,
    p.ListPrice,
    p.Weight,
    CAST(p.SellStartDate AS DATE)                             AS SellStartDate,
    CASE 
        WHEN p.SellEndDate IS NULL THEN NULL
        WHEN p.SellEndDate > '2079-06-06' THEN CAST('2079-06-06' AS DATE)
        ELSE CAST(p.SellEndDate AS DATE)
    END                                                       AS SellEndDate
INTO silver.CleanProduct
FROM bronze.Product p
LEFT JOIN bronze.ProductSubcategory sc ON p.ProductSubcategoryID = sc.ProductSubcategoryID
LEFT JOIN bronze.ProductCategory    c  ON sc.ProductCategoryID   = c.ProductCategoryID;

PRINT '✓ silver.CleanProduct — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 3 — CleanProductCostHistory
-- EndDate NULL = version courante
-- ------------------------------------------------------------
SELECT
    ProductID,
    CAST(StartDate AS DATE)                                   AS StartDate,
    CASE
        WHEN EndDate IS NULL THEN NULL
        WHEN EndDate > '2079-06-06' THEN CAST('2079-06-06' AS DATE)
        ELSE CAST(EndDate AS DATE)
    END                                                       AS EndDate,
    StandardCost,
    CASE WHEN EndDate IS NULL THEN 1 ELSE 0 END               AS IsCurrent
INTO silver.CleanProductCostHistory
FROM bronze.ProductCostHistory;

PRINT '✓ silver.CleanProductCostHistory — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 4 — CleanProductPriceHistory
-- EndDate NULL = version courante
-- ------------------------------------------------------------
SELECT
    ProductID,
    CAST(StartDate AS DATE)                                   AS StartDate,
    CASE
        WHEN EndDate IS NULL THEN NULL
        WHEN EndDate > '2079-06-06' THEN CAST('2079-06-06' AS DATE)
        ELSE CAST(EndDate AS DATE)
    END                                                       AS EndDate,
    ListPrice,
    CASE WHEN EndDate IS NULL THEN 1 ELSE 0 END               AS IsCurrent
INTO silver.CleanProductPriceHistory
FROM bronze.ProductListPriceHistory;

PRINT '✓ silver.CleanProductPriceHistory — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 5 — CleanCustomer
-- ------------------------------------------------------------
SELECT
    c.CustomerID,
    c.AccountNumber,
    p.BusinessEntityID,
    TRIM(p.FirstName + ' ' +
         ISNULL(p.MiddleName + ' ', '') +
         p.LastName)                                          AS FullName,
    p.FirstName,
    p.LastName,
    ISNULL(e.EmailAddress, 'non renseigné')                   AS EmailAddress,
    ISNULL(CAST(c.StoreID AS VARCHAR), 'Particulier')         AS CustomerType,
    c.TerritoryID
INTO silver.CleanCustomer
FROM bronze.Customer      c
JOIN  bronze.Person       p ON c.PersonID           = p.BusinessEntityID
LEFT JOIN bronze.EmailAddress e ON p.BusinessEntityID = e.BusinessEntityID;

PRINT '✓ silver.CleanCustomer — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 6 — CleanTerritory
-- ------------------------------------------------------------
SELECT
    t.TerritoryID,
    t.Name                                                    AS TerritoryName,
    t.CountryRegionCode,
    ISNULL(cr.Name, t.CountryRegionCode)                      AS CountryName,
    t.[Group]                                                 AS TerritoryGroup,
    ROUND(t.SalesYTD, 2)                                      AS SalesYTD,
    ROUND(t.SalesLastYear, 2)                                 AS SalesLastYear
INTO silver.CleanTerritory
FROM bronze.SalesTerritory t
LEFT JOIN bronze.CountryRegion cr ON t.CountryRegionCode = cr.CountryRegionCode;

PRINT '✓ silver.CleanTerritory — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 7 — CleanSalesPerson
-- ------------------------------------------------------------
SELECT
    sp.BusinessEntityID                                       AS SalesPersonID,
    TRIM(p.FirstName + ' ' +
         ISNULL(p.MiddleName + ' ', '') +
         p.LastName)                                          AS FullName,
    e.JobTitle,
    CAST(e.HireDate AS DATE)                                  AS HireDate,
    ISNULL(sp.SalesQuota, 0)                                  AS SalesQuota,
    sp.CommissionPct,
    ROUND(sp.SalesYTD, 2)                                     AS SalesYTD,
    ROUND(sp.SalesLastYear, 2)                                AS SalesLastYear,
    sp.TerritoryID
INTO silver.CleanSalesPerson
FROM bronze.SalesPerson sp
JOIN bronze.Employee    e ON sp.BusinessEntityID = e.BusinessEntityID
JOIN bronze.Person      p ON sp.BusinessEntityID = p.BusinessEntityID;

PRINT '✓ silver.CleanSalesPerson — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

PRINT '';
PRINT '══════════════════════════════════════════════════';
PRINT '✓ SILVER complet — 7 tables nettoyées et enrichies';
PRINT '══════════════════════════════════════════════════';