CREATE DATABASE IF NOT EXISTS project_2;
USE project_2;

-- DATA EXPLORATION

-- COUNT ROWS
SELECT COUNT(*) AS total_rows FROM nassau_candy_clean;

-- Sample data
SELECT * FROM nassau_candy_clean LIMIT 10;

-- Check NULL values (data quality validation)
SET SQL_SAFE_UPDATES = 0;
DELETE FROM nassau_candy_clean
WHERE Sales IS NULL 
OR Units IS NULL 
OR Gross_profit IS NULL 
OR Cost IS NULL
OR Sales <= 0 
OR Units <= 0;
SET SQL_SAFE_UPDATES = 1;
-- Dataset should have NO nulls in financial columns
-- Missing values = unreliable profitability metrics


-- CREATE VIEW
DROP VIEW IF EXISTS product_metrics;

CREATE VIEW product_metrics AS
SELECT
Product_Name,
Division,
SUM(Sales) AS total_sales,
SUM(Gross_profit) AS total_profit,
SUM(Units) AS total_units,
-- Gross Margin %
ROUND(SUM(Gross_profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS gross_margin,
-- Profit per unit
ROUND(SUM(Gross_profit) / NULLIF(SUM(Units), 0), 2) AS profit_per_unit
FROM nassau_candy_clean
GROUP BY Product_Name, Division;
-- These KPIs define TRUE business performance
-- Revenue alone is misleading without margin


-- PRODUCT PROFITABILITY ANALYSIS

-- 1 Top profit generating products
SELECT *
FROM product_metrics
ORDER BY total_profit DESC
LIMIT 10;
-- These are core revenue drivers
-- Protect pricing & ensure supply stability
-- A small number of products generate Majority of total profit


-- 2 High sales but low margin (DANGEROUS PRODUCTS)
SELECT *
FROM product_metrics
WHERE gross_margin < 15
ORDER BY total_sales DESC;
-- High revenue ≠ high profit
-- These products may be killing margins
-- Revenue illusion - looks good but hurts business


-- 3 Low sales + low profit
SELECT *
FROM product_metrics
WHERE total_sales < 50 AND total_profit < 10;
-- These products add operational complexity and do not contribute meaningfully
-- Dead weight in product portfolio -(Nerds, Fun Dip)


-- 4 Top selling products (by revenue)
SELECT
Product_Name,
SUM(Sales) AS total_sales,
SUM(Units) AS total_units
FROM nassau_candy_clean
GROUP BY Product_Name
ORDER BY total_sales DESC
LIMIT 10;
-- High demand products drive sales volume and customer traffic
-- Important for inventory planning & supply chain stability


-- 5 PRODUCT SEGMENTATION
SELECT *,
CASE
    WHEN gross_margin >= 30 THEN 'High Margin'
    WHEN gross_margin BETWEEN 15 AND 30 THEN 'Medium Margin'
    ELSE 'Low Margin'
END AS margin_category
FROM product_metrics
ORDER BY gross_margin DESC;
-- Helps categorize products for pricing strategy
-- High margin = premium products
-- Low margin = cost optimization needed


-- 6 DIVISION PERFORMANCE ANALYSIS
SELECT
Division,
SUM(Sales) AS revenue,
SUM(Gross_profit) AS profit,
(SUM(Sales) - SUM(Gross_profit)) AS total_cost,
ROUND(SUM(Gross_profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS margin
FROM nassau_candy_clean
GROUP BY Division
ORDER BY revenue DESC;
-- Identifies strong vs weak divisions
-- High revenue + low margin = structural issue
-- Shows cost-heavy divisions


-- 7 PARETO ANALYSIS (80/20 RULE)
WITH product_profit AS (
    SELECT
        Product_Name,
        SUM(Gross_profit) AS profit
    FROM nassau_candy_clean
    GROUP BY Product_Name
),
ranked AS (
    SELECT *,
        SUM(profit) OVER () AS total_profit,
        SUM(profit) OVER (ORDER BY profit DESC) AS cumulative_profit
    FROM product_profit
)
SELECT *,
ROUND(cumulative_profit / total_profit * 100, 2) AS cumulative_percentage
FROM ranked;
-- Typically ~20% products generate ~80% profit
-- Heavy dependency on few products


-- 8 COST VS MARGIN DIAGNOSTICS
SELECT
Product_Name,
SUM(Sales) AS sales,
SUM(Cost) AS total_cost,
SUM(Gross_profit) AS profit,
ROUND(SUM(Gross_profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS margin
FROM nassau_candy_clean
GROUP BY Product_Name
ORDER BY total_cost DESC;
-- Pricing issues or Cost inefficiencies identifies Profit leakage
-- High cost + low margin = pricing inefficiency


-- 9 Identify cost-heavy & low margin products
SELECT *
FROM product_metrics
WHERE gross_margin < 15
AND total_sales > 100;
-- These products generate volume but destroy profit
-- Most critical business risk


-- 10 REGION ANALYSIS (OPTIONAL ADVANCED)
SELECT
Region,
COUNT(*) AS total_orders,
SUM(Sales) AS revenue,
SUM(Gross_profit) AS profit,
ROUND(SUM(Gross_profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS margin
FROM nassau_candy_clean
GROUP BY Region
ORDER BY margin DESC;
-- Helps identify region-wise pricing differences
-- Reveals which regions are profit-efficient
-- Useful for geographic strategy
-- Interior Region is more profitable


-- 11 REGION + PRODUCT PERFORMANCE
SELECT
Region,
Product_Name,
SUM(Sales) AS total_sales,
SUM(Gross_profit) AS total_profit,
ROUND(SUM(Gross_profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS margin
FROM nassau_candy_clean
GROUP BY Region, Product_Name
ORDER BY Region, total_profit DESC;
-- Same product performs differently across regions- Profitable in one region, Loss-making in another
-- Indicates pricing or cost structure inefficiencies


-- 12 REGION - AVERAGE ORDER 
SELECT
Region,
ROUND(SUM(Sales)/COUNT(Order_ID),2) AS avg_order_value
FROM nassau_candy_clean
GROUP BY Region;
-- Region Show Higher average order value

-- 13 STATE ANALYSIS
SELECT
State,
SUM(Sales) AS total_sales,
SUM(Gross_profit) AS total_profit,
ROUND(SUM(Gross_profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS margin
FROM nassau_candy_clean
GROUP BY State
ORDER BY total_profit DESC;
-- Detects strong vs weak states
-- Useful for regional marketing & logistics optimization
-- California show high profit



-- 14 SHIPPING MODE IMPACT ON PROFIT
SELECT
Ship_mode,
SUM(Sales) AS total_sales,
SUM(Gross_profit) AS total_profit,
ROUND(SUM(Gross_profit) / NULLIF(SUM(Sales), 0) * 100, 2) AS margin
FROM nassau_candy_clean
GROUP BY Ship_mode
ORDER BY margin DESC;

-- 👉 Insight:
-- Some shipping modes may reduce profitability Some shipping modes due to Higher logistics cost
-- Helps optimize logistics cost strategy
-- Standard Class shipping generates more profit


-- 15 Risk Segmentation
SELECT *,
CASE
    WHEN gross_margin < 20 THEN 'High Risk'
    WHEN gross_margin BETWEEN 20 AND 40 THEN 'Moderate Risk'
    ELSE 'Safe'
END AS risk_category
FROM product_metrics;
-- Products classified into High Risk, Moderate & Safe
-- Helps prioritize decision-making



-- FINAL DATASET FOR POWER BI

SELECT
Ship_mode,
Country,
State,
City,
Division,
Region,
Product_Name,
Sales,
Units,
Gross_profit,
Cost,
ROUND(Gross_profit / NULLIF(Sales, 0) * 100, 2) AS gross_margin,
ROUND(Gross_profit / NULLIF(Units, 0), 2) AS profit_per_unit,
CASE
    WHEN Gross_profit / NULLIF(Sales, 0) * 100 >= 30 THEN 'High Margin'
    WHEN Gross_profit / NULLIF(Sales, 0) * 100 BETWEEN 15 AND 30 THEN 'Medium Margin'
    ELSE 'Low Margin'
END AS margin_category,
CASE
    WHEN Gross_profit < 4 THEN 'Loss Making'
    WHEN Gross_profit < 9 THEN 'Low Profit'
    ELSE 'High Profit'
END AS profit_category
FROM nassau_candy_clean;
