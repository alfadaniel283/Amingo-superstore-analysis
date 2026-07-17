USE learnsql;

---Executive SALE OVERVIEW
---identifies  if business is growing or shrinking using YoY growth %%

IF OBJECT_ID('dbo.vw_YoY_Sale_Growth') IS NOT NULL
    DROP VIEW dbo.vw_YoY_Sale_Growth
EXEC('
CREATE VIEW dbo.vw_YoY_Sale_Growth
 AS
WITH YearlySales AS (
    SELECT 
        d.year,
        SUM(s.sales) AS total_sales,
        SUM(s.profit) AS total_profit
    FROM dbo.Sale s
    JOIN Date d ON s.order_date = d.order_date
    GROUP BY d.year
)

SELECT

    year,
    total_sales,
    total_profit,
    LAG(total_sales) OVER (ORDER BY year) AS prev_year_sale,
    ((CAST(total_sales AS FLOAT) - LAG(total_sales) OVER (ORDER BY year)) / LAG(total_sales) OVER (ORDER BY year)) * 100 AS YoY_Growth_pct,
    LAG(total_profit) OVER (ORDER BY year) AS prev_year_profit
FROM YearlySales;
   ')

----=============MARGIN ANALYSIS===================
----Purpose: Identifies "Value Leakage" - high volume 
IF OBJECT_ID('dbo.vw_Profit_margin_pct') IS NOT NULL
    DROP VIEW dbo.vw_Profit_margin_pct
EXEC('

CREATE VIEW dbo.vw_Profit_margin_pct
AS 
SELECT
    p.category,
    p.sub_category,
    SUM(s.sales) AS total_sales,
    SUM(s.profit) AS total_profit,
    (SUM(s.profit) / NULLIF(SUM(s.sales), 0)) * 100 AS profit_margin_pct
FROM Sale s
JOIN Product p ON s.product_id = p.product_id
GROUP BY p.category, p.sub_category
ORDER BY profit_margin_pct DESC
OFFSET 0 ROWS;
')

---===============RFM SEGMENTATION===============
IF OBJECT_ID('dbo.vw_Customer_metrics') IS NOT NULL
    DROP VIEW dbo.vw_Customer_metrics
EXEC('

CREATE VIEW dbo.vw_Customer_metrics 
AS
WITH CustomerMetrics AS (
    SELECT
        customer_name,
        MAX(order_date) AS last_order_date,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(s.sales) AS monetary_value
    FROM Sale s
    JOIN Customer c ON s.customer_id = c.customer_id
    GROUP BY customer_name
)
SELECT
    customer_name,
    NTILE(5) OVER (ORDER BY last_order_date ASC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary_value) AS m_score
FROM CustomerMetrics;
 ')

---===DISCOUNT IMPACT STUDY
-- Purpose: Evaluates if discounts drive sales or kill profits.

IF OBJECT_ID('dbo.vw_discount_impact') IS NOT NULL
    DROP VIEW dbo.vw_discount_impact
EXEC('

CREATE VIEW vw_discount_impact 
AS
    SELECT
        CASE 
            WHEN s.discount = 0 THEN N'0% No Discount'  
            WHEN s.discount > 0 AND s.discount <=0.2 THEN N'0-20% Low' 
            WHEN s.discount > 0.2 AND s.discount <= 0.5 THEN '20-50% Mid'
            ELSE '50%+ High'
        END AS discount_bucket,
    COUNT(order_id) AS order_count,
    AVG(profit) AS avg_profit_per_order,
    SUM(sales) AS total_sales
    FROM Sale s
    GROUP BY s.discount
    ORDER BY avg_profit_per_order DESC OFFSET 0 ROWS; ---offset 0 rows allows to refer to alias in order by
')


-- =======5. SHIPPING & LOGISTICAL PERFORMANCE
-- Purpose: Measures fulfillment speed against a 4-day standard.

IF OBJECT_ID('dbo.vw_Ship_logistic_perf') IS NOT NULL
    DROP VIEW dbo.vw_Ship_logistic_perf
    
EXEC('
CREATE VIEW dbo.vw_Ship_logistic_perf 
AS
    SELECT 
            oi.ship_mode,
            l.region,
            AVG(DATEDIFF(day, d.order_date, d.ship_date)) AS avg_days_to_ship,
            MAX(DATEDIFF(day, d.order_date, d.ship_date)) AS max_order_delay_days,
            COUNT(CASE
                    WHEN DATEDIFF( day, d.order_date,d.ship_date) > 4  THEN 1 END) AS num_delayed_orders,
            COUNT(s.sales) AS total_orders
         
    FROM Sale s
    JOIN DATE d ON s.order_date = d.order_date
    JOIN Order_info oi ON s.order_id = oi.order_id
    JOIN Location l ON s.location_id = l.location_id
    GROUP BY oi.ship_mode, l.region
 ')


--=========== 6. CATEGORY & SUB-CATEGORY PARETO (80/20 RULE)
---Purpose: Finding the top products driving 80% of revenu

IF OBJECT_ID('vw_sale_drivers') IS NOT NULL
    DROP VIEW vw_sale_drivers
EXEC('

CREATE VIEW vw_sale_drivers 
AS 
WITH sub_cat_sales AS (
    SELECT  
        p.sub_category,
        SUM(s.sales) AS total_sales
    FROM Sale s
    JOIN Product p ON s.product_id = p.product_id
    GROUP BY p.sub_category
),
cumulative_sales AS (
    SELECT  
        sub_category,
        total_sales,
        SUM(total_sales) OVER (ORDER BY total_sales DESC) AS running_total,
        SUM(total_sales) OVER () AS grand_total
    FROM sub_cat_sales

)
SELECT
    sub_category,
    total_sales,
    running_total,
    grand_total,
    (CAST(running_total AS DECIMAL(10,2))/ grand_total ) * 100 AS cumulative_revenue_pct
FROM cumulative_sales
ORDER BY cumulative_revenue_pct DESC;
 ')

--===== 7. REGIONAL PROFITABILITY HEATMAP
-- Purpose: Identifies geographic areas with inefficient operations.

IF OBJECT_ID('vw_profitability_region') IS NOT NULL
    DROP VIEW vw_profitability_region
EXEC('

CREATE VIEW vw_profitability_region 
AS 
SELECT 
    l.market,
    l.country,
    l.state,
    SUM(s.sales) AS total_sales,
    SUM(s.profit) AS total_profit,
    (SUM(s.profit) / NULLIF(SUM(s.sales),0)) AS profit_ratio
FROM Sale s
JOIN Location l ON S.location_id = l.location_id
GROUP BY l.market, l.country, l.state
ORDER BY total_profit ASC
 ')

-- 8. BASKET ANALYSIS (CO-OCCURRENCE)
-- Purpose: Understanding products bought together for cross-selling.

IF OBJECT_ID('vw_basket_analysis') IS NOT NULL
    DROP VIEW vw_basket_analysis
EXEC('

CREATE VIEW vw_basket_analysis 
AS 
    SELECT
        p1.sub_category AS product_a,
        p2.sub_category AS product_b,
        COUNT(*) AS items_bought_together
    FROM Sale f1
    JOIN Sale f2 ON f1.order_id = f2.order_id AND f1.product_id < f2.product_id
    JOIN Product p1 ON f1.product_id = p1.product_id
    JOIN Product p2 ON f2.product_id = p2.product_id
    GROUP BY p1.sub_category, p2.sub_category
    ORDER BY items_bought_together DESC OFFSET 0 ROWS;

    ')

-- 9. CUSTOMER LIFETIME VALUE (CLV)
-- Purpose: Predicts total customer worth by segment.
IF OBJECT_ID('vw_clv_to_date_segment') IS NOT NULL
    DROP VIEW vw_clv_to_date_segment

EXEC('

CREATE VIEW vw_clv_to_date_segment
AS     
    SELECT
        c.segment,
        COUNT(DISTINCT c.customer_name) AS total_customers,
        AVG(s.sales) AS avg_order_value,
        SUM(s.sales) / COUNT(DISTINCT c.customer_name) AS vw_clv_to_date
    FROM Sale s
    JOIN Customer c ON s.customer_id = c.customer_id
    GROUP BY c.segment;
 ')

---======CUSTOMER LIFETIME VALUE BY CUSTOMER NAME
IF OBJECT_ID('vw_clv_to_date_customer') IS NOT NULL
    DROP VIEW vw_clv_to_date_customer
EXEC('

CREATE VIEW vw_clv_to_date_customer
AS     
  SELECT
        c.customer_name,

        AVG(s.sales) AS avg_order_value,
        SUM(s.sales) / COUNT(DISTINCT c.customer_name) AS vw_clv_to_date
    FROM Sale s
    JOIN Customer c ON s.customer_id = c.customer_id
    GROUP BY c.customer_name
    ORDER BY vw_clv_to_date DESC OFFSET 0 ROWS;
 ')


---=======CUSTOMERS SALES, PROFIT AND DISCOUNT BY QUARTERS
IF OBJECT_ID('dbo.vw_quarter_analysis') IS NOT NULL
    DROP VIEW dbo.vw_quarter_analysis

EXEC('
CREATE VIEW vw_quarter_analysis
AS
    SELECT
        d.[year],
        CONCAT('Q', DATEPART(QUARTER, s.order_date)) AS year_quarter,
        SUM(s.discount) AS discount_quarter,
        COUNT(s.sales) AS customer_quarterly,
        SUM(s.sales) AS total_sales_quarter,
        SUM(s.profit) AS total_profit_quarter
    FROM Sale s   
    JOIN Customer c ON s.customer_id = c.customer_id
    JOIN Date d ON s.order_date = d.order_date
    GROUP BY CONCAT('Q', DATEPART(QUARTER, s.order_date)), [year];
')
