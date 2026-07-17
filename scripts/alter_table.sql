USE learnsql
GO

BEGIN TRY
    BEGIN TRANSACTION

    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN product_id NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN product_name NVARCHAR(300) NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN category NVARCHAR(100) NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN sub_category NVARCHAR(100) NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN customer_name NVARCHAR(300) NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN segment NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN state NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN country NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN market NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN region NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN order_id NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN ship_mode NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN order_priority NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN sales INT NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN quantity INT NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN discount DECIMAL NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN profit DECIMAL NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN ship_cost DECIMAL NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN order_date DATETIME NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN ship_date DATETIME NOT NULL;
    ALTER TABLE dbo.SuperStoreOrder
    ALTER COLUMN year INT NOT NULL;
    

        COMMIT TRANSACTION;
    PRINT 'datatype correction completed'

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Error:' + ERROR_MESSAGE();

END CATCH;

--===============ALTERING STAR SCHEMA TABLES
BEGIN TRY
    BEGIN TRANSACTION
 ALTER TABLE dbo.Product
    ALTER COLUMN product_id NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.Product
    ALTER COLUMN product_name NVARCHAR(300) NOT NULL;
    ALTER TABLE dbo.Product
    ALTER COLUMN category NVARCHAR(100) NOT NULL;
    ALTER TABLE dbo.Product
    ALTER COLUMN sub_category NVARCHAR(100) NOT NULL;
    ALTER TABLE dbo.Customer
    ALTER COLUMN customer_name NVARCHAR(300) NOT NULL;
    ALTER TABLE dbo.Customer
    ALTER COLUMN segment NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.Location
    ALTER COLUMN state NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.Location
    ALTER COLUMN country NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.Location
    ALTER COLUMN market NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.Location
    ALTER COLUMN region NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.Order_info
    ALTER COLUMN order_id NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.Order_info
    ALTER COLUMN ship_mode NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.Order_info
    ALTER COLUMN order_priority NVARCHAR(50) NOT NULL;
    ALTER TABLE sale
    ALTER COLUMN sales INT NOT NULL;
    ALTER TABLE dbo.sale
    ALTER COLUMN quantity INT NOT NULL;
    ALTER TABLE dbo.sale
    ALTER COLUMN discount DECIMAL NOT NULL;
    ALTER TABLE dbo.sale
    ALTER COLUMN profit DECIMAL NOT NULL;
    ALTER TABLE dbo.sale
    ALTER COLUMN ship_cost DECIMAL NOT NULL;
    ALTER TABLE dbo.sale
    ALTER COLUMN customer_name NVARCHAR(300) NOT NULL;
    ALTER TABLE dbo.sale
    ALTER COLUMN product_id NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.sale
    ALTER COLUMN customer_name NVARCHAR(300) NOT NULL;

    COMMIT TRANSACTION
    PRINT 'altered star schema tableS'

END TRY
    BEGIN CATCH
    ROLLBACK TRANSACTION
    PRINT 'Error:' + ERROR_MESSAGE();

END CATCH;

USE learnsql

SELECT  
    d.year,
    COUNT(DISTINCT order_id) AS sale_frequency 
    FROM Sale s
JOIN Date d ON s.order_date = d.order_date
GROUP BY year

SELECT
    p.sub_category,
    DATEDIFF(day, d.order_date, d.ship_date)-  AVG(DATEDIFF(day, d.order_date, d.ship_date)) AS delayed_shipping
FROM Date d
JOIN Sale s ON d.order_date = s.order_date
JOIN Product p ON s.product_id = p.product_id
WHERE DATEDIFF(day, d.order_date, d.ship_date) > 4





--WITH SubCatorySale AS (
    SELECT 
    p.sub_category,
    SUM(s.sales) AS total_sales,
    SUM(s.sales)/@grand_sales as grand_total

FROM Sale s
JOIN Product p ON s.product_id = p.product_id
GROUP BY p.sub_category  
--)
DECLARE @grand_sales AS INT = ( SELECT
    COUNT(sales) as total_sales
from Sale s
)
SELECT @grand_sales AS grand_sale



----======
SELECT * FROM dbo.Sale