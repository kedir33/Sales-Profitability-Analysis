/*
PROJECT: Sales & Profitability Analysis (SQL)
AUTHOR: Kedir Mohammod
DESCRIPTION:
End-to-end SQL project including data cleaning, validation, 
and business analysis to identify profitability trends 
and loss-making segments.
*/

USE Portfolio_Projects;
GO

-------------------------------------------------------
-- 0. RESET 
-------------------------------------------------------

-- Drop table if it already exists 
IF OBJECT_ID('Sales_Clean', 'U') IS NOT NULL
    DROP TABLE Sales_Clean;


-------------------------------------------------------
-- 1. INITIAL DATA EXPLORATION
-------------------------------------------------------

SELECT TOP 10 * FROM Sales;

SELECT COUNT(*) AS Total_Rows_Original FROM Sales;


-------------------------------------------------------
-- 2. DATA CLEANING
-------------------------------------------------------

-- 2.1 Check for duplicates BEFORE cleaning
SELECT 
    Ship_Mode, Segment, Country, City, State, Postal_Code,
    Region, Category, Sub_Category, Sales, Quantity, Discount, Profit,
    COUNT(*) AS duplicate_count
FROM Sales
GROUP BY 
    Ship_Mode, Segment, Country, City, State, Postal_Code,
    Region, Category, Sub_Category, Sales, Quantity, Discount, Profit
HAVING COUNT(*) > 1;


-- 2.2 Remove duplicates using ROW_NUMBER()
WITH CTE_Duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY 
                   Ship_Mode,
                   Segment,
                   Country,
                   City,
                   State,
                   Postal_Code,
                   Region,
                   Category,
                   Sub_Category,
                   Sales,
                   Quantity,
                   Discount,
                   Profit
               ORDER BY (SELECT NULL)
           ) AS row_num
    FROM Sales
)
SELECT *
INTO Sales_Clean
FROM CTE_Duplicates
WHERE row_num = 1;


-- 2.3 Check NULL values
SELECT 
    SUM(CASE WHEN Ship_Mode IS NULL THEN 1 ELSE 0 END) AS Missing_Ship_Mode,
    SUM(CASE WHEN Segment IS NULL THEN 1 ELSE 0 END) AS Missing_Segment,
    SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END) AS Missing_Country,
    SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS Missing_City,
    SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS Missing_State,
    SUM(CASE WHEN Postal_Code IS NULL THEN 1 ELSE 0 END) AS Missing_Postal_Code,
    SUM(CASE WHEN Region IS NULL THEN 1 ELSE 0 END) AS Missing_Region,
    SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS Missing_Category,
    SUM(CASE WHEN Sub_Category IS NULL THEN 1 ELSE 0 END) AS Missing_Sub_Category,
    SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) AS Missing_Sales,
    SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END) AS Missing_Quantity,
    SUM(CASE WHEN Discount IS NULL THEN 1 ELSE 0 END) AS Missing_Discount,
    SUM(CASE WHEN Profit IS NULL THEN 1 ELSE 0 END) AS Missing_Profit
FROM Sales_Clean;


-- 2.4 Remove rows with missing financial data
DELETE FROM Sales_Clean
WHERE Sales IS NULL OR Profit IS NULL;


-------------------------------------------------------
-- 3. DATA STANDARDIZATION CHECK
-------------------------------------------------------

SELECT DISTINCT Ship_Mode FROM Sales_Clean;
SELECT DISTINCT Segment FROM Sales_Clean;
SELECT DISTINCT Region FROM Sales_Clean;
SELECT DISTINCT Category FROM Sales_Clean;
SELECT DISTINCT Sub_Category FROM Sales_Clean;


-------------------------------------------------------
-- 4. BUSINESS ANALYSIS
-------------------------------------------------------

-- 4.1 Category Performance
SELECT 
    Category,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2) AS Profit_Margin_Pct
FROM Sales_Clean
GROUP BY Category
ORDER BY Total_Profit DESC;


-- 4.2 Sub-Category Deep Dive
SELECT 
    Sub_Category,
    ROUND(SUM(Sales), 2) AS Total_Sales,
    ROUND(SUM(Profit), 2) AS Total_Profit,
    ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2) AS Profit_Margin_Pct
FROM Sales_Clean
GROUP BY Sub_Category
ORDER BY Total_Profit ASC;


-- 4.3 Loss-Making Sub-Categories
SELECT 
    Sub_Category,
    ROUND(SUM(Profit), 2) AS Total_Profit
FROM Sales_Clean
GROUP BY Sub_Category
HAVING SUM(Profit) < 0
ORDER BY Total_Profit;


-- 4.4 Regional Analysis (Tables)
SELECT 
    Region,
    ROUND(SUM(Sales), 2) AS Table_Sales,
    ROUND(SUM(Profit), 2) AS Table_Profit
FROM Sales_Clean
WHERE Sub_Category = 'Tables'
GROUP BY Region
ORDER BY Table_Profit ASC;


-- 4.5 Sales Ranking
SELECT 
    Category,
    SUM(Sales) AS Total_Sales,
    RANK() OVER (ORDER BY SUM(Sales) DESC) AS Sales_Rank
FROM Sales_Clean
GROUP BY Category;


-- 4.6 Sales Contribution %
SELECT 
    Category,
    SUM(Sales) AS Total_Sales,
    ROUND(
        SUM(Sales) * 100.0 / SUM(SUM(Sales)) OVER (), 
    2) AS Sales_Percentage
FROM Sales_Clean
GROUP BY Category;


-------------------------------------------------------
-- 5. INSIGHTS (FOR README)
-------------------------------------------------------

/*
- Furniture category shows weaker profitability
- "Tables" is the main loss-driving sub-category
- Losses vary by region → possible logistics/pricing issue
- High revenue ≠ high profit → margin matters

RECOMMENDATIONS:
- Adjust pricing strategy
- Reduce costs in weak regions
- Focus on high-margin products
*/