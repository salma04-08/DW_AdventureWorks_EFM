-- ============================================================
-- 03_gold_dimensions.sql
-- ============================================================

USE DW_SalesPerformance_AW;
GO

-- ------------------------------------------------------------
-- Nettoyage
-- ------------------------------------------------------------
IF OBJECT_ID('gold.FactSales')       IS NOT NULL DROP TABLE gold.FactSales;
IF OBJECT_ID('gold.DimDate')         IS NOT NULL DROP TABLE gold.DimDate;
IF OBJECT_ID('gold.DimProduct')      IS NOT NULL DROP TABLE gold.DimProduct;
IF OBJECT_ID('gold.DimCustomer')     IS NOT NULL DROP TABLE gold.DimCustomer;
IF OBJECT_ID('gold.DimTerritory')    IS NOT NULL DROP TABLE gold.DimTerritory;
IF OBJECT_ID('gold.DimSalesPerson')  IS NOT NULL DROP TABLE gold.DimSalesPerson;
GO

-- ============================================================
-- DIMENSION 1 — DimDate
-- ============================================================
CREATE TABLE gold.DimDate (
    DateKey         INT          NOT NULL PRIMARY KEY,
    FullDate        DATE         NOT NULL,
    DayOfWeek       TINYINT      NOT NULL,
    DayName         VARCHAR(10)  NOT NULL,
    DayOfMonth      TINYINT      NOT NULL,
    DayOfYear       SMALLINT     NOT NULL,
    WeekOfYear      TINYINT      NOT NULL,
    Month           TINYINT      NOT NULL,
    MonthName       VARCHAR(10)  NOT NULL,
    Quarter         TINYINT      NOT NULL,
    QuarterName     VARCHAR(6)   NOT NULL,
    Year            SMALLINT     NOT NULL,
    IsWeekend       BIT          NOT NULL,
    FiscalYear      SMALLINT     NOT NULL,
    FiscalQuarter   TINYINT      NOT NULL
);
GO

DECLARE @StartDate DATE = '2010-01-01';
DECLARE @EndDate   DATE = '2025-12-31';
DECLARE @Date      DATE = @StartDate;
DECLARE @Count     INT  = 0;

WHILE @Date <= @EndDate
BEGIN
    INSERT INTO gold.DimDate (
        DateKey, FullDate, DayOfWeek, DayName,
        DayOfMonth, DayOfYear, WeekOfYear,
        Month, MonthName, Quarter, QuarterName,
        Year, IsWeekend, FiscalYear, FiscalQuarter
    )
    VALUES (
        CAST(FORMAT(@Date, 'yyyyMMdd') AS INT),
        @Date,
        DATEPART(WEEKDAY,   @Date),
        DATENAME(WEEKDAY,   @Date),
        DAY(@Date),
        DATEPART(DAYOFYEAR, @Date),
        DATEPART(WEEK,      @Date),
        MONTH(@Date),
        DATENAME(MONTH,     @Date),
        DATEPART(QUARTER,   @Date),
        'T' + CAST(DATEPART(QUARTER, @Date) AS VARCHAR),
        YEAR(@Date),
        CASE WHEN DATEPART(WEEKDAY, @Date) IN (1,7) THEN 1 ELSE 0 END,
        CASE WHEN MONTH(@Date) >= 7 THEN YEAR(@Date)+1 ELSE YEAR(@Date) END,
        CASE
            WHEN MONTH(@Date) IN (7,8,9)    THEN 1
            WHEN MONTH(@Date) IN (10,11,12) THEN 2
            WHEN MONTH(@Date) IN (1,2,3)    THEN 3
            ELSE 4
        END
    );
    SET @Date  = DATEADD(DAY, 1, @Date);
    SET @Count = @Count + 1;
END

PRINT '✓ gold.DimDate — ' + CAST(@Count AS VARCHAR) + ' lignes';
GO

-- ============================================================
-- DIMENSION 2 — DimProduct (SCD Type 2)
-- ============================================================
CREATE TABLE gold.DimProduct (
    ProductKey      INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    ProductID       INT           NOT NULL,
    ProductName     VARCHAR(100)  NOT NULL,
    ProductNumber   VARCHAR(25)   NOT NULL,
    CategoryName    VARCHAR(50)   NOT NULL,
    SubcategoryName VARCHAR(50)   NOT NULL,
    Color           VARCHAR(20)   NOT NULL,
    StandardCost    DECIMAL(18,2) NOT NULL,
    ListPrice       DECIMAL(18,2) NOT NULL,
    Weight          DECIMAL(8,2)  NULL,
    StartDate       DATE          NOT NULL,
    EndDate         DATE          NULL,
    DWStartDate     DATE          NOT NULL,
    DWEndDate       DATE          NULL,
    IsCurrent       BIT           NOT NULL DEFAULT 1
);
GO

INSERT INTO gold.DimProduct (
    ProductID, ProductName, ProductNumber,
    CategoryName, SubcategoryName, Color,
    StandardCost, ListPrice, Weight,
    StartDate, EndDate,
    DWStartDate, DWEndDate, IsCurrent
)
SELECT
    cp.ProductID,
    cp.ProductName,
    cp.ProductNumber,
    cp.CategoryName,
    cp.SubcategoryName,
    cp.Color,
    cch.StandardCost,
    ISNULL(cph.ListPrice, cp.ListPrice)  AS ListPrice,
    cp.Weight,
    cch.StartDate                        AS StartDate,
    cch.EndDate                          AS EndDate,
    cch.StartDate                        AS DWStartDate,
    cch.EndDate                          AS DWEndDate,
    cch.IsCurrent
FROM silver.CleanProduct cp
JOIN silver.CleanProductCostHistory  cch ON cp.ProductID   = cch.ProductID
LEFT JOIN silver.CleanProductPriceHistory cph
    ON  cp.ProductID   = cph.ProductID
    AND cch.StartDate  = cph.StartDate;

PRINT '✓ gold.DimProduct — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes (SCD Type 2)';
GO

-- ============================================================
-- DIMENSION 3 — DimCustomer
-- ============================================================
CREATE TABLE gold.DimCustomer (
    CustomerKey     INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    CustomerID      INT           NOT NULL,
    AccountNumber   VARCHAR(20)   NOT NULL,
    FullName        VARCHAR(150)  NOT NULL,
    FirstName       VARCHAR(50)   NOT NULL,
    LastName        VARCHAR(50)   NOT NULL,
    EmailAddress    VARCHAR(100)  NOT NULL,
    CustomerType    VARCHAR(20)   NOT NULL,
    TerritoryID     INT           NOT NULL
);
GO

INSERT INTO gold.DimCustomer (
    CustomerID, AccountNumber, FullName,
    FirstName, LastName, EmailAddress,
    CustomerType, TerritoryID
)
SELECT
    CustomerID, AccountNumber, FullName,
    FirstName, LastName, EmailAddress,
    CustomerType, TerritoryID
FROM silver.CleanCustomer;

PRINT '✓ gold.DimCustomer — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ============================================================
-- DIMENSION 4 — DimTerritory
-- ============================================================
CREATE TABLE gold.DimTerritory (
    TerritoryKey        INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    TerritoryID         INT           NOT NULL,
    TerritoryName       VARCHAR(50)   NOT NULL,
    CountryRegionCode   VARCHAR(5)    NOT NULL,
    CountryName         VARCHAR(100)  NOT NULL,
    TerritoryGroup      VARCHAR(50)   NOT NULL,
    SalesYTD            DECIMAL(18,2) NOT NULL,
    SalesLastYear       DECIMAL(18,2) NOT NULL
);
GO

INSERT INTO gold.DimTerritory (
    TerritoryID, TerritoryName, CountryRegionCode,
    CountryName, TerritoryGroup, SalesYTD, SalesLastYear
)
SELECT
    TerritoryID, TerritoryName, CountryRegionCode,
    CountryName, TerritoryGroup, SalesYTD, SalesLastYear
FROM silver.CleanTerritory;

PRINT '✓ gold.DimTerritory — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ============================================================
-- DIMENSION 5 — DimSalesPerson
-- TerritoryID NULL autorisé — certains vendeurs n'ont pas de territoire
-- ============================================================
CREATE TABLE gold.DimSalesPerson (
    SalesPersonKey  INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    SalesPersonID   INT           NOT NULL,
    FullName        VARCHAR(150)  NOT NULL,
    JobTitle        VARCHAR(100)  NOT NULL,
    HireDate        DATE          NOT NULL,
    SalesQuota      DECIMAL(18,2) NOT NULL,
    CommissionPct   DECIMAL(5,4)  NOT NULL,
    SalesYTD        DECIMAL(18,2) NOT NULL,
    SalesLastYear   DECIMAL(18,2) NOT NULL,
    TerritoryID     INT           NULL       -- ← NULL autorisé
);
GO

-- Ligne spéciale ventes en ligne
SET IDENTITY_INSERT gold.DimSalesPerson ON;
INSERT INTO gold.DimSalesPerson (
    SalesPersonKey, SalesPersonID, FullName, JobTitle,
    HireDate, SalesQuota, CommissionPct,
    SalesYTD, SalesLastYear, TerritoryID
)
VALUES (-1, -1, 'Vente en ligne', 'Online Channel',
        '2000-01-01', 0, 0, 0, 0, NULL);
SET IDENTITY_INSERT gold.DimSalesPerson OFF;

INSERT INTO gold.DimSalesPerson (
    SalesPersonID, FullName, JobTitle,
    HireDate, SalesQuota, CommissionPct,
    SalesYTD, SalesLastYear, TerritoryID
)
SELECT
    SalesPersonID, FullName, JobTitle,
    HireDate, SalesQuota, CommissionPct,
    SalesYTD, SalesLastYear, TerritoryID
FROM silver.CleanSalesPerson;

PRINT '✓ gold.DimSalesPerson — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes (+1 vente en ligne)';
GO

PRINT '';
PRINT '══════════════════════════════════════════════════════════════';
PRINT '✓ GOLD DIMENSIONS complet — 5 dimensions chargées';
PRINT '══════════════════════════════════════════════════════════════';