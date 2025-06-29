-- 1. CREATE DATABASE
CREATE DATABASE IF NOT EXISTS retail_eda;
USE retail_eda;

-- 2. CREATE TABLE STRUCTURE
DROP TABLE IF EXISTS online_retail;

CREATE TABLE online_retail (
    Invoice VARCHAR(20),
    StockCode VARCHAR(20),
    Description TEXT,
    Quantity INT,
    InvoiceDate DATETIME,
    UnitPrice DECIMAL(10, 2),
    CustomerID VARCHAR(20),
    Country VARCHAR(50)
);

-- 3. LOAD DATA FROM CSV FILE
-- 'local_infile=1' was enabled on both client and server

LOAD DATA LOCAL INFILE 'C:/Users/praty/OneDrive/Desktop/Project_ANALYTICS/online_retail.csv'
INTO TABLE online_retail
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Invoice, StockCode, Description, Quantity, InvoiceDate, UnitPrice, CustomerID, Country);

-- 4. CREATED A CLEANED VIEW FOR ANALYSIS
CREATE OR REPLACE VIEW retail_clean AS
SELECT
    *,
    Quantity * UnitPrice AS TotalPrice,
    CASE WHEN Invoice LIKE 'C%' THEN 1 ELSE 0 END AS IsReturn
FROM
    online_retail
WHERE
    Quantity != 0
    AND UnitPrice >= 0
    AND Description IS NOT NULL;

-- 5. ANALYTICS QUERIES

-- 5.1 Top 10 Most Sold Products
SELECT Description AS Product, SUM(Quantity) AS UnitsSold
FROM retail_clean
WHERE IsReturn = 0
GROUP BY Product
ORDER BY UnitsSold DESC
LIMIT 10;

-- 5.2 Revenue by Country
SELECT Country, ROUND(SUM(TotalPrice), 2) AS Revenue
FROM retail_clean
WHERE IsReturn = 0
GROUP BY Country
ORDER BY Revenue DESC;

-- 5.3 Monthly Revenue Trend
SELECT DATE_FORMAT(InvoiceDate, '%Y-%m') AS Month, ROUND(SUM(TotalPrice), 2) AS MonthlyRevenue
FROM retail_clean
WHERE IsReturn = 0
GROUP BY Month
ORDER BY Month;

-- 5.4 Sales by Hour of Day
SELECT HOUR(InvoiceDate) AS Hour, ROUND(SUM(TotalPrice), 2) AS Revenue
FROM retail_clean
WHERE IsReturn = 0
GROUP BY Hour
ORDER BY Hour;

-- 5.5 Sales by Weekday
SELECT DAYNAME(InvoiceDate) AS DayOfWeek, ROUND(SUM(TotalPrice), 2) AS Revenue
FROM retail_clean
WHERE IsReturn = 0
GROUP BY DayOfWeek;

-- 5.6 Top 10 Returned Products
SELECT Description AS Product, COUNT(*) AS ReturnCount
FROM retail_clean
WHERE IsReturn = 1
GROUP BY Product
ORDER BY ReturnCount DESC
LIMIT 10;

-- 5.7 Top Countries by Unique Customers
SELECT Country, COUNT(DISTINCT CustomerID) AS UniqueCustomers
FROM retail_clean
WHERE CustomerID IS NOT NULL
GROUP BY Country
ORDER BY UniqueCustomers DESC
LIMIT 10;

-- 5.8 Countries with Highest Return Value
SELECT Country, ROUND(SUM(TotalPrice), 2) AS ReturnValue
FROM retail_clean
WHERE IsReturn = 1
GROUP BY Country
ORDER BY ReturnValue DESC
LIMIT 10;

-- 5.9 Customer Acquisition Trend
SELECT DATE_FORMAT(MIN(InvoiceDate), '%Y-%m') AS FirstPurchaseMonth,
       COUNT(DISTINCT CustomerID) AS NewCustomers
FROM retail_clean
WHERE CustomerID IS NOT NULL
GROUP BY FirstPurchaseMonth
ORDER BY FirstPurchaseMonth;

-- 5.10 RFM Segmentation (Base Table)
SELECT
    CustomerID,
    DATEDIFF('2011-12-10', MAX(InvoiceDate)) AS Recency,
    COUNT(DISTINCT Invoice) AS Frequency,
    ROUND(SUM(TotalPrice), 2) AS Monetary
FROM retail_clean
WHERE CustomerID IS NOT NULL AND IsReturn = 0
GROUP BY CustomerID;

-- 5.11 Total Revenue and Returns
SELECT ROUND(SUM(TotalPrice), 2) AS TotalRevenue FROM retail_clean WHERE IsReturn = 0;
SELECT ROUND(SUM(TotalPrice), 2) AS TotalReturnValue FROM retail_clean WHERE IsReturn = 1;
