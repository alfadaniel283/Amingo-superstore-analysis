
POPULATING TABLES SQL QUERY
-- 1. Populate Customers
INSERT INTO Customers (CustomerName, Segment)
SELECT DISTINCT customer_name, segment FROM Raw_Superstore;

-- 2. Populate Products
INSERT INTO Products (ProductID, ProductName, Category, Sub_category)
SELECT DISTINCT product_id, product_name, category, sub_category FROM Raw_Superstore;

-- 3. Populate Regions
INSERT INTO Regions ([State], Country, Market, RegionName)
SELECT DISTINCT [state], country, market, region FROM Raw_Superstore;

-- 4. Populate Orders (The Complex One)
INSERT INTO Orders (OrderID, OrderDate, ShipDate, ShipMode, OrderPriority, CustomerID, ProductID, RegionID, Sales, Quantity, Discount, Profit, ShippingCost, [Year])
SELECT 
    r.order_id, r.order_date, r.ship_date, r.ship_mode, r.order_priority,
    c.CustomerID, 
    p.ProductID, 
    reg.RegionID,
    r.sales, r.quantity, r.discount, r.profit, r.shipping_cost, r.[year]
FROM Raw_Superstore r
JOIN Customers c ON r.customer_name = c.CustomerName AND r.segment = c.Segment
JOIN Products p ON r.product_id = p.ProductID
JOIN Regions reg ON r.[state] = reg.[State] AND r.region = reg.RegionName;


===================SQL QUERY FOR THE REQUIRED REPORT===========
/* 
================================================================================
SQL QUERIES FOR INDUSTRIAL SALES ANALYSIS (STAR SCHEMA)
================================================================================
This file contains 10 queries based on the defined Star Schema:
Fact_Sales, Dim_Product, Dim_Customer, Dim_Location, Dim_Order_Info, Dim_Date
================================================================================
*/

-- 1. EXECUTIVE SALES OVERVIEW
-- Purpose: Identifies if business is growing or shrinking using YoY Growth %.
WITH YearlySales AS (
    SELECT 
        d.year,
        SUM(f.sales) AS total_sales,
        SUM(f.profit) AS total_profit
    FROM Fact_Sales f
    JOIN Dim_Date d ON f.order_date = d.order_date
    GROUP BY d.year
)
SELECT 
    year,
    total_sales,
    total_profit,
    LAG(total_sales) OVER (ORDER BY year) AS prev_year_sales,
    ((total_sales - LAG(total_sales) OVER (ORDER BY year)) / NULLIF(LAG(total_sales) OVER (ORDER BY year), 0)) * 100 AS YoY_Growth_Pct
FROM YearlySales;


-- 2. PROFIT MARGIN ANALYSIS
-- Purpose: Identifies "Value Leakage" - high volume but low/negative profit items.
SELECT 
    p.category,
    p.sub_category,
    SUM(f.sales) AS total_sales,
    SUM(f.profit) AS total_profit,
    (SUM(f.profit) / NULLIF(SUM(f.sales), 0)) * 100 AS profit_margin_pct
FROM Fact_Sales f
JOIN Dim_Product p ON f.product_id = p.product_id
GROUP BY p.category, p.sub_category
ORDER BY profit_margin_pct ASC;


-- 3. RFM SEGMENTATION
-- Purpose: Segments customers by value (Recency, Frequency, Monetary).
WITH CustomerMetrics AS (
    SELECT 
        customer_name,
        MAX(order_date) AS last_order_date,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(sales) AS monetary
    FROM Fact_Sales
    GROUP BY customer_name
)
SELECT 
    customer_name,
    NTILE(5) OVER (ORDER BY last_order_date ASC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
FROM CustomerMetrics;


-- 4. DISCOUNT IMPACT STUDY
-- Purpose: Evaluates if discounts drive sales or kill profits.
SELECT 
    CASE 
        WHEN discount = 0 THEN '0% No Discount'
        WHEN discount > 0 AND discount <= 0.2 THEN '0-20% Low'
        WHEN discount > 0.2 AND discount <= 0.5 THEN '20-50% Mid'
        ELSE '50%+ High' 
    END AS discount_bucket,
    COUNT(order_id) AS order_count,
    AVG(profit) AS avg_profit_per_order,
    SUM(sales) AS total_sales
FROM Fact_Sales
GROUP BY 1
ORDER BY avg_profit_per_order DESC;


-- 5. SHIPPING & LOGISTICAL PERFORMANCE
-- Purpose: Measures fulfillment speed against a 4-day standard.
SELECT 
    i.ship_mode,
    l.region,
    AVG(DATEDIFF(day, d.order_date, d.ship_date)) AS avg_days_to_ship,
    COUNT(CASE WHEN DATEDIFF(day, d.order_date, d.ship_date) > 4 THEN 1 END) AS delayed_orders
FROM Fact_Sales f
JOIN Dim_Date d ON f.order_date = d.order_date
JOIN Dim_Order_Info i ON f.order_id = i.order_id
JOIN Dim_Location l ON f.location_id = l.location_id
GROUP BY i.ship_mode, l.region;


-- 6. CATEGORY & SUB-CATEGORY PARETO (80/20 RULE)
-- Purpose: Finding the top products driving 80% of revenue.
WITH SubCatSales AS (
    SELECT 
        p.sub_category,
        SUM(f.sales) AS total_sales
    FROM Fact_Sales f
    JOIN Dim_Product p ON f.product_id = p.product_id
    GROUP BY p.sub_category
),
CumulativeSales AS (
    SELECT 
        sub_category,
        total_sales,
        SUM(total_sales) OVER (ORDER BY total_sales DESC) AS running_total,
        SUM(total_sales) OVER () AS grand_total
    FROM SubCatSales
)
SELECT 
    sub_category,
    total_sales,
    (running_total / grand_total) * 100 AS cumulative_revenue_pct
FROM CumulativeSales;


-- 7. REGIONAL PROFITABILITY HEATMAP
-- Purpose: Identifies geographic areas with inefficient operations.
SELECT 
    l.market,
    l.country,
    l.state,
    SUM(f.sales) AS total_sales,
    SUM(f.profit) AS total_profit,
    (SUM(f.profit) / NULLIF(SUM(f.sales), 0)) AS profit_ratio
FROM Fact_Sales f
JOIN Dim_Location l ON f.location_id = l.location_id
GROUP BY l.market, l.country, l.state
ORDER BY total_profit ASC;


-- 8. BASKET ANALYSIS (CO-OCCURRENCE)
-- Purpose: Understanding products bought together for cross-selling.
SELECT 
    p1.sub_category AS product_a,
    p2.sub_category AS product_b,
    COUNT(*) AS times_bought_together
FROM Fact_Sales f1
JOIN Fact_Sales f2 ON f1.order_id = f2.order_id AND f1.product_id < f2.product_id
JOIN Dim_Product p1 ON f1.product_id = p1.product_id
JOIN Dim_Product p2 ON f2.product_id = p2.product_id
GROUP BY p1.sub_category, p2.sub_category
ORDER BY times_bought_together DESC
LIMIT 10;


-- 9. CUSTOMER LIFETIME VALUE (CLV)
-- Purpose: Predicts total customer worth by segment.
SELECT 
    c.segment,
    COUNT(DISTINCT f.customer_name) AS total_customers,
    AVG(f.sales) AS avg_order_value,
    SUM(f.sales) / COUNT(DISTINCT f.customer_name) AS clv_to_date
FROM Fact_Sales f
JOIN Dim_Customer c ON f.customer_name = c.customer_name
GROUP BY c.segment;


-- 10. RETURNS ANALYSIS
-- Note: Assuming a Return Flag or Returns table exists.
SELECT 
    p.category,
    COUNT(f.order_id) AS total_orders,
    -- This part assumes a column indicating if an item was returned
    SUM(CASE WHEN f.profit < 0 AND f.discount > 0.7 THEN 1 ELSE 0 END) AS proxy_return_count, 
    (CAST(SUM(CASE WHEN f.profit < 0 AND f.discount > 0.7 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(f.order_id)) * 100 AS est_return_rate_pct
FROM Fact_Sales f
JOIN Dim_Product p ON f.product_id = p.product_id
GROUP BY p.category
ORDER BY est_return_rate_pct DESC;
