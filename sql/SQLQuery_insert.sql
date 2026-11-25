
IF DB_ID(N'SupplyChainDB1') IS NULL CREATE DATABASE SupplyChainDB1;
USE SupplyChainDB1;
GO

-- 1) Drop (reverse order because of foreign keys)
DROP TABLE IF EXISTS dbo.FraudLabels;
DROP TABLE IF EXISTS dbo.FactInventoryAdjustments;
DROP TABLE IF EXISTS dbo.FactReturns;
DROP TABLE IF EXISTS dbo.FactInvoices;
DROP TABLE IF EXISTS dbo.FactPurchases;
DROP TABLE IF EXISTS dbo.FactInventory;
DROP TABLE IF EXISTS dbo.FactShipments;
DROP TABLE IF EXISTS dbo.FactOrders;
DROP TABLE IF EXISTS dbo.DimCarrier;
DROP TABLE IF EXISTS dbo.DimEmployee;
DROP TABLE IF EXISTS dbo.DimWarehouse;
DROP TABLE IF EXISTS dbo.DimSupplier;
DROP TABLE IF EXISTS dbo.DimProduct;
DROP TABLE IF EXISTS dbo.DimCustomer;
DROP TABLE IF EXISTS dbo.DimLocation;
DROP TABLE IF EXISTS dbo.DimDate;
GO

-- 2) Tables, primary keys, foreign keys
CREATE TABLE dbo.DimDate (
    Date                  date NOT NULL,
    Year                  smallint NOT NULL,
    QuarterNo             tinyint NOT NULL,
    Quarter               char(2) NOT NULL,
    Month                 tinyint NOT NULL,
    MonthName             char(3) NOT NULL,
    YearMonth             char(7) NOT NULL,
    MonthSort             int NOT NULL,
    WeekNo                tinyint NOT NULL,
    DayName               char(3) NOT NULL,
    IsWeekend             bit NOT NULL,
    CONSTRAINT PK_DimDate PRIMARY KEY (Date)
);
GO
CREATE TABLE dbo.DimLocation (
    LocationID            int NOT NULL,
    Country               nvarchar(60) NOT NULL,
    Region                nvarchar(40) NOT NULL,
    City                  nvarchar(60) NOT NULL,
    District              nvarchar(40) NOT NULL,
    Lat                   decimal(9,5) NOT NULL,
    Lng                   decimal(9,5) NOT NULL,
    CONSTRAINT PK_DimLocation PRIMARY KEY (LocationID)
);
GO
CREATE TABLE dbo.DimCustomer (
    CustomerID            int NOT NULL,
    CustomerName          nvarchar(150) NOT NULL,
    Segment               nvarchar(20) NOT NULL,
    LocationID            int NOT NULL,
    JoinDate              date NOT NULL,
    CONSTRAINT PK_DimCustomer PRIMARY KEY (CustomerID),
    CONSTRAINT FK_DimCustomer_LocationID FOREIGN KEY (LocationID) REFERENCES dbo.DimLocation(LocationID)
);
GO
CREATE TABLE dbo.DimProduct (
    ProductID             int NOT NULL,
    SKU                   varchar(20) NOT NULL,
    ProductName           nvarchar(120) NOT NULL,
    Category              nvarchar(40) NOT NULL,
    Subcategory           nvarchar(40) NOT NULL,
    Brand                 nvarchar(40) NOT NULL,
    UnitCost              decimal(12,2) NOT NULL,
    UnitPrice             decimal(12,2) NOT NULL,
    WeightKg              decimal(10,2) NOT NULL,
    CONSTRAINT PK_DimProduct PRIMARY KEY (ProductID)
);
GO
CREATE TABLE dbo.DimSupplier (
    SupplierID            int NOT NULL,
    SupplierName          nvarchar(120) NOT NULL,
    Country               nvarchar(40) NOT NULL,
    LeadTimeDays          int NOT NULL,
    LeadTimeVariability   decimal(6,1) NOT NULL,
    ReliabilityScore      decimal(5,3) NOT NULL,
    Tier                  char(1) NOT NULL,
    PaymentTermsDays      int NOT NULL,
    RegistrationDate      date NOT NULL,
    AddressType           nvarchar(20) NOT NULL,
    BankAccountID         varchar(20) NOT NULL,
    TaxID                 varchar(20) NOT NULL,
    CONSTRAINT PK_DimSupplier PRIMARY KEY (SupplierID)
);
GO
CREATE TABLE dbo.DimWarehouse (
    WarehouseID           int NOT NULL,
    WarehouseName         nvarchar(120) NOT NULL,
    WarehouseType         nvarchar(40) NOT NULL,
    LocationID            int NOT NULL,
    CapacityUnits         int NOT NULL,
    OpenedDate            date NOT NULL,
    CONSTRAINT PK_DimWarehouse PRIMARY KEY (WarehouseID),
    CONSTRAINT FK_DimWarehouse_LocationID FOREIGN KEY (LocationID) REFERENCES dbo.DimLocation(LocationID)
);
GO
CREATE TABLE dbo.DimEmployee (
    EmployeeID            int NOT NULL,
    EmployeeName          nvarchar(80) NOT NULL,
    Department            nvarchar(30) NOT NULL,
    JobTitle              nvarchar(40) NOT NULL,
    ApprovalLimit         decimal(14,2) NOT NULL,
    HireDate              date NOT NULL,
    LocationID            int NOT NULL,
    BankAccountID         varchar(20) NOT NULL,
    CONSTRAINT PK_DimEmployee PRIMARY KEY (EmployeeID),
    CONSTRAINT FK_DimEmployee_LocationID FOREIGN KEY (LocationID) REFERENCES dbo.DimLocation(LocationID)
);
GO
CREATE TABLE dbo.DimCarrier (
    CarrierID             int NOT NULL,
    CarrierName           nvarchar(80) NOT NULL,
    Mode                  nvarchar(10) NOT NULL,
    ServiceLevel          nvarchar(15) NOT NULL,
    TransitDays           int NOT NULL,
    CostPerKg             decimal(8,3) NOT NULL,
    CONSTRAINT PK_DimCarrier PRIMARY KEY (CarrierID)
);
GO
CREATE TABLE dbo.FactOrders (
    OrderID               int NOT NULL,
    OrderDate             date NOT NULL,
    CustomerID            int NOT NULL,
    ProductID             int NOT NULL,
    Qty                   int NOT NULL,
    UnitPrice             decimal(12,2) NOT NULL,
    Discount              decimal(5,3) NOT NULL,
    Revenue               decimal(14,2) NOT NULL,
    Cost                  decimal(14,2) NOT NULL,
    CONSTRAINT PK_FactOrders PRIMARY KEY (OrderID),
    CONSTRAINT FK_FactOrders_OrderDate FOREIGN KEY (OrderDate) REFERENCES dbo.DimDate(Date),
    CONSTRAINT FK_FactOrders_CustomerID FOREIGN KEY (CustomerID) REFERENCES dbo.DimCustomer(CustomerID),
    CONSTRAINT FK_FactOrders_ProductID FOREIGN KEY (ProductID) REFERENCES dbo.DimProduct(ProductID)
);
GO
CREATE TABLE dbo.FactShipments (
    ShipmentID            int NOT NULL,
    OrderID               int NOT NULL,
    CarrierID             int NOT NULL,
    ShipDate              date NOT NULL,
    PromisedDate          date NOT NULL,
    DeliveryDate          date NOT NULL,
    DelayDays             int NOT NULL,
    IsOnTime              bit NOT NULL,
    WeightKg              decimal(12,1) NOT NULL,
    FreightCost           decimal(12,2) NOT NULL,
    CONSTRAINT PK_FactShipments PRIMARY KEY (ShipmentID),
    CONSTRAINT FK_FactShipments_OrderID FOREIGN KEY (OrderID) REFERENCES dbo.FactOrders(OrderID),
    CONSTRAINT FK_FactShipments_CarrierID FOREIGN KEY (CarrierID) REFERENCES dbo.DimCarrier(CarrierID),
    CONSTRAINT FK_FactShipments_ShipDate FOREIGN KEY (ShipDate) REFERENCES dbo.DimDate(Date),
    CONSTRAINT FK_FactShipments_PromisedDate FOREIGN KEY (PromisedDate) REFERENCES dbo.DimDate(Date),
    CONSTRAINT FK_FactShipments_DeliveryDate FOREIGN KEY (DeliveryDate) REFERENCES dbo.DimDate(Date)
);
GO
CREATE TABLE dbo.FactInventory (
    SnapshotDate          date NOT NULL,
    ProductID             int NOT NULL,
    WarehouseID           int NOT NULL,
    OnHand                int NOT NULL,
    ReorderPoint          int NOT NULL,
    CONSTRAINT PK_FactInventory PRIMARY KEY (SnapshotDate, ProductID, WarehouseID),
    CONSTRAINT FK_FactInventory_SnapshotDate FOREIGN KEY (SnapshotDate) REFERENCES dbo.DimDate(Date),
    CONSTRAINT FK_FactInventory_ProductID FOREIGN KEY (ProductID) REFERENCES dbo.DimProduct(ProductID),
    CONSTRAINT FK_FactInventory_WarehouseID FOREIGN KEY (WarehouseID) REFERENCES dbo.DimWarehouse(WarehouseID)
);
GO
CREATE TABLE dbo.FactPurchases (
    POID                  int NOT NULL,
    SupplierID            int NOT NULL,
    ProductID             int NOT NULL,
    PODate                date NOT NULL,
    ReceivedDate          date NOT NULL,
    QtyOrdered            int NOT NULL,
    QtyReceived           int NOT NULL,
    UnitCost              decimal(12,2) NOT NULL,
    TotalCost             decimal(16,2) NOT NULL,
    CONSTRAINT PK_FactPurchases PRIMARY KEY (POID),
    CONSTRAINT FK_FactPurchases_SupplierID FOREIGN KEY (SupplierID) REFERENCES dbo.DimSupplier(SupplierID),
    CONSTRAINT FK_FactPurchases_ProductID FOREIGN KEY (ProductID) REFERENCES dbo.DimProduct(ProductID),
    CONSTRAINT FK_FactPurchases_PODate FOREIGN KEY (PODate) REFERENCES dbo.DimDate(Date),
    CONSTRAINT FK_FactPurchases_ReceivedDate FOREIGN KEY (ReceivedDate) REFERENCES dbo.DimDate(Date)
);
GO
CREATE TABLE dbo.FactInvoices (
    InvoiceID             int NOT NULL,
    POID                  int NOT NULL,
    SupplierID            int NOT NULL,
    InvoiceNo             varchar(30) NOT NULL,
    InvoiceDate           date NOT NULL,
    InvoiceAmount         decimal(16,2) NOT NULL,
    PaymentDate           date NULL,
    PaidAmount            decimal(16,2) NOT NULL,
    PaymentStatus         varchar(10) NOT NULL,
    PaymentMethod         varchar(20) NOT NULL,
    CreatedBy             int NOT NULL,
    ApprovedBy            int NOT NULL,
    CreatedHour           tinyint NOT NULL,
    CONSTRAINT PK_FactInvoices PRIMARY KEY (InvoiceID),
    CONSTRAINT FK_FactInvoices_POID FOREIGN KEY (POID) REFERENCES dbo.FactPurchases(POID),
    CONSTRAINT FK_FactInvoices_SupplierID FOREIGN KEY (SupplierID) REFERENCES dbo.DimSupplier(SupplierID),
    CONSTRAINT FK_FactInvoices_InvoiceDate FOREIGN KEY (InvoiceDate) REFERENCES dbo.DimDate(Date),
    CONSTRAINT FK_FactInvoices_PaymentDate FOREIGN KEY (PaymentDate) REFERENCES dbo.DimDate(Date),
    CONSTRAINT FK_FactInvoices_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES dbo.DimEmployee(EmployeeID),
    CONSTRAINT FK_FactInvoices_ApprovedBy FOREIGN KEY (ApprovedBy) REFERENCES dbo.DimEmployee(EmployeeID)
);
GO
CREATE TABLE dbo.FactReturns (
    ReturnID              int NOT NULL,
    OrderID               int NOT NULL,
    ReturnDate            date NOT NULL,
    QtyReturned           int NOT NULL,
    RefundAmount          decimal(14,2) NOT NULL,
    Reason                nvarchar(40) NOT NULL,
    ApprovedBy            int NOT NULL,
    Status                varchar(15) NOT NULL,
    CONSTRAINT PK_FactReturns PRIMARY KEY (ReturnID),
    CONSTRAINT FK_FactReturns_OrderID FOREIGN KEY (OrderID) REFERENCES dbo.FactOrders(OrderID),
    CONSTRAINT FK_FactReturns_ReturnDate FOREIGN KEY (ReturnDate) REFERENCES dbo.DimDate(Date),
    CONSTRAINT FK_FactReturns_ApprovedBy FOREIGN KEY (ApprovedBy) REFERENCES dbo.DimEmployee(EmployeeID)
);
GO
CREATE TABLE dbo.FactInventoryAdjustments (
    AdjustmentID          int NOT NULL,
    AdjustmentDate        date NOT NULL,
    ProductID             int NOT NULL,
    WarehouseID           int NOT NULL,
    QtyAdjusted           int NOT NULL,
    AdjustmentValue       decimal(14,2) NOT NULL,
    Reason                nvarchar(30) NOT NULL,
    ApprovedBy            int NOT NULL,
    PostedHour            tinyint NOT NULL,
    CONSTRAINT PK_FactInventoryAdjustments PRIMARY KEY (AdjustmentID),
    CONSTRAINT FK_FactInventoryAdjustments_AdjustmentDate FOREIGN KEY (AdjustmentDate) REFERENCES dbo.DimDate(Date),
    CONSTRAINT FK_FactInventoryAdjustments_ProductID FOREIGN KEY (ProductID) REFERENCES dbo.DimProduct(ProductID),
    CONSTRAINT FK_FactInventoryAdjustments_WarehouseID FOREIGN KEY (WarehouseID) REFERENCES dbo.DimWarehouse(WarehouseID),
    CONSTRAINT FK_FactInventoryAdjustments_ApprovedBy FOREIGN KEY (ApprovedBy) REFERENCES dbo.DimEmployee(EmployeeID)
);
GO
CREATE TABLE dbo.FraudLabels (
    LabelID               int NOT NULL,
    Scenario              nvarchar(40) NOT NULL,
    SourceTable           varchar(30) NOT NULL,
    RecordID              varchar(20) NOT NULL,
    Severity              varchar(10) NOT NULL,
    Note                  nvarchar(150) NOT NULL,
    CONSTRAINT PK_FraudLabels PRIMARY KEY (LabelID)
);
----------------------------------------------
-- 3) Inser Data To Table From csv Files
-----------------------------------------------
GO


BULK INSERT dbo.DimCarrier
FROM 'D:\Project Team 1\Project\Sql\Sql\csv\DimCarrier.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);

GO


BULK INSERT dbo.DimCustomer
FROM 'D:\Project Team 1\Project\Sql\Sql\csv\DimCustomer.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);

GO


BULK INSERT dbo.DimDate
FROM 'D:\Project Team 1\Project\Sql\Sql\csv\DimDate.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);

GO


BULK INSERT dbo.DimEmployee
FROM 'D:\Project Team 1\Project\Sql\Sql\csv\DimEmployee.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);

GO


BULK INSERT dbo.DimProduct
FROM 'D:\Project Team 1\Project\Sql\Sql\csv\DimProduct.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);

GO




BULK INSERT dbo.DimLocation
FROM 'D:\Project Team 1\Project\Sql\Sql\csv\DimLocation.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);


GO




BULK INSERT dbo.DimSupplier
FROM 'D:\Project Team 1\Project\Sql\Sql\csv\DimSupplier.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);


GO




BULK INSERT dbo.DimWarehouse
FROM 'D:\Project Team 1\Project\Sql\Sql\csv\DimWarehouse.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);

GO



BULK INSERT dbo.FactInventory
FROM 'D:\Project Team 1\Project\Sql\Sql\csv\FactInventory.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);



GO

BULK INSERT dbo.FactInvoices
FROM 'D:\Project Team 1\Project\Sql\Sql\csv\FactInvoices.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);



GO

BULK INSERT dbo.FactOrders
FROM 'D:\Project Team 1\Project\Sql\Sql\csv\FactOrders.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);

GO

BULK INSERT dbo.FactPurchases
FROM 'D:\Project Team 1\Project\Sql\Sql\csv\FactPurchases.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);

GO

BULK INSERT dbo.FactReturns
FROM 'D:\Project Team 1\Project\Sql\Sql\csv\FactReturns.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);

GO

BULK INSERT dbo.FactShipments
FROM 'D:\Project Team 1\Project\Sql\Sql\csv\FactShipments.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);

/*
================================================================

Domain: Supply Chain
Database: SupplyChainDB1

================================================================
*/

USE SupplyChainDB1;
GO

-- Q1. Display all columns from the Customers table.
-- ANSWER:
SELECT *
FROM DimCustomer;


-- Q2. Display all products.
--  ANSWER:
SELECT *
FROM DimProduct;


-- Q3. Display only ProductID, ProductName, and UnitPrice.
-- ANSWER:
SELECT ProductID, ProductName, UnitPrice
FROM DimProduct;


-- Q4. Display only EmployeeName and JobTitle from employees.
--  ANSWER:
SELECT EmployeeName, JobTitle
FROM DimEmployee;


-- Q5. Display the first 10 customers.
--  ANSWER:
SELECT TOP 10 *
FROM DimCustomer;


-- Q6. Display all different product categories.
--  ANSWER:
SELECT DISTINCT Category
FROM DimProduct;


-- Q7. Display all different customer segments.
--  ANSWER:
SELECT DISTINCT Segment
FROM DimCustomer;


-- Q8. Display products with a UnitPrice greater than 500.
--  ANSWER:
SELECT ProductID, ProductName, UnitPrice
FROM DimProduct
WHERE UnitPrice > 500;


-- Q9. Display products with a UnitPrice less than 100.
--  ANSWER:
SELECT ProductID, ProductName, UnitPrice
FROM DimProduct
WHERE UnitPrice < 100;


-- Q10. Display customers whose Segment is 'Retail'.
--  ANSWER:
SELECT CustomerID, CustomerName, Segment
FROM DimCustomer
WHERE Segment = 'Retail';


-- Q11. Display employees who work in the 'Finance' department.
--  ANSWER:
SELECT EmployeeID, EmployeeName, Department
FROM   DimEmployee
WHERE Department = 'Finance';


-- Q12. Display orders with Qty greater than 5.
--  ANSWER:
SELECT OrderID, ProductID, Qty
FROM   FactOrders
WHERE Qty > 5;


-- Q13. Display shipments where DelayDays is greater than 0.
--  ANSWER:
SELECT ShipmentID, OrderID, DelayDays
FROM   FactShipments
WHERE DelayDays > 0;


-- Q14. Display products with UnitPrice between 100 and 500.
--  ANSWER:
SELECT ProductID, ProductName, UnitPrice
FROM  DimProduct
WHERE UnitPrice BETWEEN 100 AND 500;


-- Q15. Display customers whose Segment is either 'Retail' or 'Corporate'.
--  ANSWER:
SELECT CustomerID, CustomerName, Segment
FROM   DimCustomer
WHERE Segment IN ('Retail', 'Corporate');


-- Q16. Display products whose Category is 'Electronics' or 'Furniture'.
--  ANSWER:
SELECT ProductID, ProductName, Category
FROM  DimProduct
WHERE Category = 'Electronics'
   OR Category = 'Furniture';


-- Q17. Display employees whose Department is 'Finance'
-- and whose ApprovalLimit is greater than 10000.
--  ANSWER:
SELECT EmployeeID, EmployeeName, Department, ApprovalLimit
FROM DimEmployee
WHERE Department = 'Finance'
  AND ApprovalLimit > 10000;


-- Q18. Display customers whose names start with the letter 'A'.
--  ANSWER:
SELECT CustomerID, CustomerName
FROM   DimCustomer
WHERE CustomerName LIKE 'A%';


-- Q19. Display products whose names contain the word 'Phone'.
--  ANSWER:
SELECT ProductID, ProductName
FROM   DimProduct
WHERE ProductName LIKE '%Phone%';

-- Q20. Display products from the highest UnitPrice to the lowest.
--  ANSWER:
SELECT ProductName, UnitPrice
FROM   DimProduct
ORDER BY UnitPrice DESC;


-- Q21. Display the 5 cheapest products.
--  ANSWER:
SELECT TOP 5 ProductID, ProductName, UnitPrice
FROM DimProduct
ORDER BY UnitPrice ASC;


-- Q22. Display the 10 most recent orders.
--  ANSWER:
SELECT TOP 10 OrderID, OrderDate, Revenue
FROM  FactOrders
ORDER BY OrderDate DESC;


-- Q23. Display employees alphabetically by EmployeeName.
--  ANSWER:
SELECT EmployeeID, EmployeeName, Department
FROM DimEmployee
ORDER BY EmployeeName ASC;


-- Q24. Count the total number of customers.
--  ANSWER:
SELECT COUNT(*) AS TotalCustomers
FROM DimCustomer;


-- Q25. Count the total number of products.
--  ANSWER:
SELECT COUNT(*) AS TotalProducts
FROM DimProduct;


-- Q26. Calculate the total revenue from all orders.
--  ANSWER:
SELECT SUM(Revenue) AS TotalRevenue
FROM FactOrders;


-- Q27. Calculate the average product UnitPrice.
--  ANSWER:
SELECT AVG(UnitPrice) AS AverageProductPrice
FROM DimProduct;


-- Q28. Find the highest and lowest product prices.
--  ANSWER:
SELECT MAX(UnitPrice) AS HighestPrice,
       MIN(UnitPrice) AS LowestPrice
FROM DimProduct;


-- Q29. Calculate the total number of units sold.
--  ANSWER:
SELECT SUM(Qty) AS TotalUnitsSold
FROM FactOrders;


-- Q30. Count the number of customers in each Segment.
--  ANSWER:
SELECT Segment, COUNT(*) AS CustomerCount
FROM DimCustomer
GROUP BY Segment;


-- Q31. Count the number of products in each Category.
--  ANSWER:
SELECT Category, COUNT(*) AS ProductCount
FROM DimProduct
GROUP BY Category;


-- Q32. Calculate total revenue for each order date.
--  ANSWER:
SELECT OrderDate, SUM(Revenue) AS DailyRevenue
FROM  FactOrders
GROUP BY OrderDate
ORDER BY OrderDate;


-- Q33. Count shipments for each CarrierID.
--  ANSWER:
SELECT CarrierID, COUNT(*) AS ShipmentCount
FROM FactShipments
GROUP BY CarrierID;


-- Q34. Calculate total inventory units in each warehouse.
--  ANSWER:
SELECT WarehouseID, SUM(OnHand) AS TotalUnits
FROM FactInventory
GROUP BY WarehouseID;



-- Q35. Find the 5 products with the highest UnitPrice.
--  ANSWER:
SELECT TOP 5 ProductName, Category, UnitPrice
FROM DimProduct
ORDER BY UnitPrice DESC;


-- Q36. Find the 5 customers with the most orders.
--  ANSWER:
SELECT TOP 5 CustomerID, COUNT(*) AS TotalOrders
FROM FactOrders
GROUP BY CustomerID
ORDER BY TotalOrders DESC;


-- Q37. Count how many shipments are on time and how many are late.
-- IsOnTime = 1 means on time; IsOnTime = 0 means not on time.
--  ANSWER:
SELECT IsOnTime, COUNT(*) AS ShipmentCount
FROM FactShipments
GROUP BY IsOnTime;


-- Q38. Calculate total purchase cost for each supplier.
--  ANSWER:
SELECT SupplierID, SUM(TotalCost) AS TotalPurchaseCost
FROM FactPurchases
GROUP BY SupplierID
ORDER BY TotalPurchaseCost DESC;


-- Q39. Display invoices where PaidAmount is less than InvoiceAmount.
--  ANSWER:
SELECT InvoiceID, InvoiceNo, InvoiceAmount, PaidAmount
FROM FactInvoices
WHERE PaidAmount < InvoiceAmount;


-- Q40. Display inventory records where OnHand is below ReorderPoint.
--  ANSWER:
SELECT SnapshotDate, ProductID, WarehouseID, OnHand, ReorderPoint
FROM  FactInventory
WHERE OnHand < ReorderPoint;

-- Q41. Display all orders with the customer name.
-- ANSWER:
SELECT
    o.OrderID,
    c.CustomerName
FROM FactOrders o
INNER JOIN DimCustomer c
    ON o.CustomerID = c.CustomerID;


--Q42. Display order ID, customer name, and product name.
--ANSWER:
SELECT
    o.OrderID,
    c.CustomerName,
    p.ProductName
FROM FactOrders o
INNER JOIN DimCustomer c
    ON o.CustomerID = c.CustomerID
INNER JOIN DimProduct p
    ON o.ProductID = p.ProductID;



--Q43. Display all customers, including customers who have no orders.
--ANSWER:
SELECT
    c.CustomerID,
    c.CustomerName,
    o.OrderID
FROM DimCustomer c
LEFT JOIN FactOrders o
    ON c.CustomerID = o.CustomerID;

--Q44. Find customers who have never placed an order.
--ANSWER:
SELECT
    c.CustomerID,
    c.CustomerName
FROM DimCustomer c
LEFT JOIN FactOrders o
    ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;

--Q45. Display all warehouses and their inventory records, including warehouses without inventory records.
--ANSWER:
SELECT
    w.WarehouseID,
    i.ProductID,
    i.OnHand
FROM DimWarehouse w
LEFT JOIN FactInventory i
    ON w.WarehouseID = i.WarehouseID;

    
--Q46. Display delayed shipments, sorted by the highest delay.
--ANSWER:
SELECT
    s.ShipmentID,
    c.CarrierName,
    s.DelayDays
FROM FactShipments s
INNER JOIN DimCarrier c
    ON s.CarrierID = c.CarrierID
WHERE s.DelayDays > 0
ORDER BY s.DelayDays DESC;


--Q47. Count the number of orders for each customer, including customers with zero orders.
--ANSWER:
SELECT
    c.CustomerID,
    c.CustomerName,
    COUNT(o.OrderID) AS TotalOrders
FROM DimCustomer c
LEFT JOIN FactOrders o
    ON c.CustomerID = o.CustomerID
GROUP BY
    c.CustomerID,
    c.CustomerName;


--Q48. Calculate total inventory quantity for each product.
--ANSWER:
SELECT
    p.ProductName,
    COALESCE(SUM(i.OnHand), 0) AS TotalInventory
FROM DimProduct p
LEFT JOIN FactInventory i
    ON p.ProductID = i.ProductID
GROUP BY p.ProductName
ORDER BY TotalInventory DESC;
------------------------------------------------------------------>>>>>>