-- ============================================================
-- 01_bronze.sql
-- Chargement brut des 14 tables sources AdventureWorks2022
-- Aucune transformation — copie fidèle des données sources
-- ============================================================
-- ------------------------------------------------------------
-- Nettoyage (permet de re-exécuter le script sans erreur)
-- ------------------------------------------------------------
IF OBJECT_ID('bronze.SalesOrderHeader')        IS NOT NULL DROP TABLE bronze.SalesOrderHeader;
IF OBJECT_ID('bronze.SalesOrderDetail')        IS NOT NULL DROP TABLE bronze.SalesOrderDetail;
IF OBJECT_ID('bronze.Product')                 IS NOT NULL DROP TABLE bronze.Product;
IF OBJECT_ID('bronze.ProductSubcategory')      IS NOT NULL DROP TABLE bronze.ProductSubcategory;
IF OBJECT_ID('bronze.ProductCategory')         IS NOT NULL DROP TABLE bronze.ProductCategory;
IF OBJECT_ID('bronze.ProductCostHistory')      IS NOT NULL DROP TABLE bronze.ProductCostHistory;
IF OBJECT_ID('bronze.ProductListPriceHistory') IS NOT NULL DROP TABLE bronze.ProductListPriceHistory;
IF OBJECT_ID('bronze.Customer')                IS NOT NULL DROP TABLE bronze.Customer;
IF OBJECT_ID('bronze.Person')                  IS NOT NULL DROP TABLE bronze.Person;
IF OBJECT_ID('bronze.EmailAddress')            IS NOT NULL DROP TABLE bronze.EmailAddress;
IF OBJECT_ID('bronze.SalesTerritory')          IS NOT NULL DROP TABLE bronze.SalesTerritory;
IF OBJECT_ID('bronze.SalesPerson')             IS NOT NULL DROP TABLE bronze.SalesPerson;
IF OBJECT_ID('bronze.Employee')                IS NOT NULL DROP TABLE bronze.Employee;
IF OBJECT_ID('bronze.CountryRegion')           IS NOT NULL DROP TABLE bronze.CountryRegion;
GO

-- ------------------------------------------------------------
-- TABLE 1 — SalesOrderHeader
-- Source : Sales.SalesOrderHeader
-- Rôle   : Entêtes de commandes — dates, client, vendeur, territoire
-- ------------------------------------------------------------
SELECT
    SalesOrderID,
    OrderDate,
    DueDate,
    ShipDate,
    Status,
    CustomerID,
    SalesPersonID,
    TerritoryID,
    SubTotal,
    TaxAmt,
    Freight,
    TotalDue,
    OnlineOrderFlag,
    PurchaseOrderNumber,
    AccountNumber
INTO bronze.SalesOrderHeader
FROM AdventureWorks2019.Sales.SalesOrderHeader;

PRINT '✓ bronze.SalesOrderHeader chargée — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 2 — SalesOrderDetail
-- Source : Sales.SalesOrderDetail
-- Rôle   : Lignes de commandes — quantités, prix, remises
-- ------------------------------------------------------------
SELECT
    SalesOrderDetailID,
    SalesOrderID,
    ProductID,
    OrderQty,
    UnitPrice,
    UnitPriceDiscount,
    LineTotal
INTO bronze.SalesOrderDetail
FROM AdventureWorks2019.Sales.SalesOrderDetail;

PRINT '✓ bronze.SalesOrderDetail chargée — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 3 — Product
-- Source : Production.Product
-- Rôle   : Fiche produit de base
-- ------------------------------------------------------------
SELECT
    ProductID,
    Name,
    ProductNumber,
    ProductSubcategoryID,
    Color,
    StandardCost,
    ListPrice,
    Weight,
    SellStartDate,
    SellEndDate
INTO bronze.Product
FROM AdventureWorks2019.Production.Product;

PRINT '✓ bronze.Product chargée — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 4 — ProductSubcategory
-- Source : Production.ProductSubcategory
-- Rôle   : Sous-catégorie produit (Bikes, Helmets...)
-- ------------------------------------------------------------
SELECT
    ProductSubcategoryID,
    ProductCategoryID,
    Name
INTO bronze.ProductSubcategory
FROM AdventureWorks2019.Production.ProductSubcategory;

PRINT '✓ bronze.ProductSubcategory chargée — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 5 — ProductCategory
-- Source : Production.ProductCategory
-- Rôle   : Catégorie produit (Bikes, Clothing, Accessories...)
-- ------------------------------------------------------------
SELECT
    ProductCategoryID,
    Name
INTO bronze.ProductCategory
FROM AdventureWorks2019.Production.ProductCategory;

PRINT '✓ bronze.ProductCategory chargée — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 6 — ProductCostHistory
-- Source : Production.ProductCostHistory
-- Rôle   : Historique des coûts standard — SOURCE NATURELLE SCD TYPE 2
--          Chaque ligne = une version du coût avec StartDate/EndDate
-- ------------------------------------------------------------
SELECT
    ProductID,
    StartDate,
    EndDate,
    StandardCost
INTO bronze.ProductCostHistory
FROM AdventureWorks2019.Production.ProductCostHistory;

PRINT '✓ bronze.ProductCostHistory chargée — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 7 — ProductListPriceHistory
-- Source : Production.ProductListPriceHistory
-- Rôle   : Historique des prix catalogue — SOURCE NATURELLE SCD TYPE 2
--          Chaque ligne = une version du prix avec StartDate/EndDate
-- ------------------------------------------------------------
SELECT
    ProductID,
    StartDate,
    EndDate,
    ListPrice
INTO bronze.ProductListPriceHistory
FROM AdventureWorks2019.Production.ProductListPriceHistory;

PRINT '✓ bronze.ProductListPriceHistory chargée — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 8 — Customer
-- Source : Sales.Customer
-- Rôle   : Liaison entre CustomerID et PersonID
-- ------------------------------------------------------------
SELECT
    CustomerID,
    PersonID,
    StoreID,
    TerritoryID,
    AccountNumber
INTO bronze.Customer
FROM AdventureWorks2019.Sales.Customer;

PRINT '✓ bronze.Customer chargée — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 9 — Person
-- Source : Person.Person
-- Rôle   : Nom et prénom des clients et vendeurs
-- ------------------------------------------------------------
SELECT
    BusinessEntityID,
    FirstName,
    MiddleName,
    LastName,
    PersonType,
    EmailPromotion
INTO bronze.Person
FROM AdventureWorks2019.Person.Person;

PRINT '✓ bronze.Person chargée — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 10 — EmailAddress
-- Source : Person.EmailAddress
-- Rôle   : Adresse email des clients
-- ------------------------------------------------------------
SELECT
    BusinessEntityID,
    EmailAddress
INTO bronze.EmailAddress
FROM AdventureWorks2019.Person.EmailAddress;

PRINT '✓ bronze.EmailAddress chargée — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 11 — SalesTerritory
-- Source : Sales.SalesTerritory
-- Rôle   : Zones géographiques de vente + CA par territoire
-- ------------------------------------------------------------
SELECT
    TerritoryID,
    Name,
    CountryRegionCode,
    [Group],
    SalesYTD,
    SalesLastYear
INTO bronze.SalesTerritory
FROM AdventureWorks2019.Sales.SalesTerritory;

PRINT '✓ bronze.SalesTerritory chargée — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 12 — SalesPerson
-- Source : Sales.SalesPerson
-- Rôle   : Quotas, commissions et performance des vendeurs
-- ------------------------------------------------------------
SELECT
    BusinessEntityID,
    TerritoryID,
    SalesQuota,
    CommissionPct,
    SalesYTD,
    SalesLastYear
INTO bronze.SalesPerson
FROM AdventureWorks2019.Sales.SalesPerson;

PRINT '✓ bronze.SalesPerson chargée — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 13 — Employee
-- Source : HumanResources.Employee
-- Rôle   : Informations RH des vendeurs (titre, date embauche)
-- ------------------------------------------------------------
SELECT
    BusinessEntityID,
    JobTitle,
    HireDate,
    BirthDate,
    Gender
INTO bronze.Employee
FROM AdventureWorks2019.HumanResources.Employee;

PRINT '✓ bronze.Employee chargée — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

-- ------------------------------------------------------------
-- TABLE 14 — CountryRegion
-- Source : Person.CountryRegion
-- Rôle   : Nom complet du pays à partir du code ISO
-- ------------------------------------------------------------
SELECT
    CountryRegionCode,
    Name
INTO bronze.CountryRegion
FROM AdventureWorks2019.Person.CountryRegion;

PRINT '✓ bronze.CountryRegion chargée — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes';
GO

PRINT '';
PRINT '══════════════════════════════════════════';
PRINT '✓ BRONZE complet — 14 tables chargées';
PRINT '══════════════════════════════════════════';