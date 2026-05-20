-- ============================================================
-- 04_gold_fact.sql
-- Création et chargement de la table de faits FactSales
-- Jointures sur toutes les dimensions via Lookup
-- ============================================================

USE DW_SalesPerformance_AW;
GO

-- ------------------------------------------------------------
-- Nettoyage
-- ------------------------------------------------------------
IF OBJECT_ID('gold.FactSales') IS NOT NULL DROP TABLE gold.FactSales;
GO

-- ------------------------------------------------------------
-- Création FactSales
-- ------------------------------------------------------------
CREATE TABLE gold.FactSales (
    FactSalesKey        INT           NOT NULL IDENTITY(1,1) PRIMARY KEY,
    -- Clés étrangères vers les dimensions
    DateKey             INT           NOT NULL,
    ProductKey          INT           NOT NULL,
    CustomerKey         INT           NOT NULL,
    TerritoryKey        INT           NOT NULL,
    SalesPersonKey      INT           NOT NULL,
    -- Clés métier (pour traçabilité)
    SalesOrderID        INT           NOT NULL,
    SalesOrderDetailID  INT           NOT NULL,
    -- Mesures
    OrderQuantity       INT           NOT NULL,
    UnitPrice           DECIMAL(18,2) NOT NULL,
    Discount            DECIMAL(5,4)  NOT NULL,
    SalesAmount         DECIMAL(18,2) NOT NULL,
    TotalCost           DECIMAL(18,2) NOT NULL,
    Profit              DECIMAL(18,2) NOT NULL,
    -- Indicateurs
    OnlineOrderFlag     BIT           NOT NULL,
    -- Contraintes FK
    CONSTRAINT FK_FactSales_DimDate        FOREIGN KEY (DateKey)        REFERENCES gold.DimDate(DateKey),
    CONSTRAINT FK_FactSales_DimProduct     FOREIGN KEY (ProductKey)     REFERENCES gold.DimProduct(ProductKey),
    CONSTRAINT FK_FactSales_DimCustomer    FOREIGN KEY (CustomerKey)    REFERENCES gold.DimCustomer(CustomerKey),
    CONSTRAINT FK_FactSales_DimTerritory   FOREIGN KEY (TerritoryKey)   REFERENCES gold.DimTerritory(TerritoryKey),
    CONSTRAINT FK_FactSales_DimSalesPerson FOREIGN KEY (SalesPersonKey) REFERENCES gold.DimSalesPerson(SalesPersonKey)
);
GO

PRINT '✓ gold.FactSales — table créée';
GO

-- ------------------------------------------------------------
-- Chargement FactSales
-- Lookup sur chaque dimension pour récupérer les clés techniques
-- ------------------------------------------------------------
INSERT INTO gold.FactSales (
    DateKey, ProductKey, CustomerKey,
    TerritoryKey, SalesPersonKey,
    SalesOrderID, SalesOrderDetailID,
    OrderQuantity, UnitPrice, Discount,
    SalesAmount, TotalCost, Profit,
    OnlineOrderFlag
)
SELECT
    -- DateKey : format YYYYMMDD depuis OrderDate
    CAST(FORMAT(cs.OrderDate, 'yyyyMMdd') AS INT)       AS DateKey,

    -- ProductKey : version SCD2 active à la date de commande
    dp.ProductKey,

    -- CustomerKey
    dc.CustomerKey,

    -- TerritoryKey
    dt.TerritoryKey,

    -- SalesPersonKey (-1 si vente en ligne)
    ISNULL(dsp.SalesPersonKey, -1)                      AS SalesPersonKey,

    -- Clés métier
    cs.SalesOrderID,
    cs.SalesOrderDetailID,

    -- Mesures
    cs.OrderQuantity,
    cs.UnitPrice,
    cs.Discount,
    cs.SalesAmount,
    cs.TotalCost,
    cs.Profit,
    cs.OnlineOrderFlag

FROM silver.CleanSales cs

-- Lookup DimProduct : version SCD2 valide à la date de commande
JOIN gold.DimProduct dp
    ON  cs.ProductID   = dp.ProductID
    AND cs.OrderDate  >= dp.DWStartDate
    AND (dp.DWEndDate IS NULL OR cs.OrderDate < dp.DWEndDate)

-- Lookup DimCustomer
JOIN gold.DimCustomer dc
    ON cs.CustomerID = dc.CustomerID

-- Lookup DimTerritory
JOIN gold.DimTerritory dt
    ON cs.TerritoryID = dt.TerritoryID

-- Lookup DimSalesPerson (LEFT JOIN car peut être NULL = vente en ligne)
LEFT JOIN gold.DimSalesPerson dsp
    ON  cs.SalesPersonID = dsp.SalesPersonID
    AND dsp.SalesPersonID <> -1;

PRINT '✓ gold.FactSales — ' + CAST(@@ROWCOUNT AS VARCHAR) + ' lignes chargées';
GO

-- ------------------------------------------------------------
-- Vérification rapide
-- ------------------------------------------------------------
SELECT
    COUNT(*)                        AS NbLignes,
    SUM(SalesAmount)                AS CA_Total,
    SUM(Profit)                     AS Profit_Total,
    ROUND(SUM(Profit)/SUM(SalesAmount)*100, 2) AS TauxMarge_Pct,
    MIN(DateKey)                    AS PremiereDateKey,
    MAX(DateKey)                    AS DerniereDateKey
FROM gold.FactSales;
GO

PRINT '';
PRINT '══════════════════════════════════════════════════════════════';
PRINT '✓ GOLD FACT complet — FactSales chargée';
PRINT '══════════════════════════════════════════════════════════════';