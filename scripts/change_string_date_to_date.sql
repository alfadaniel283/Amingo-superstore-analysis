use learnsql;

ALTER TABLE SuperStoreOrder
ADD order_date_new DATETIME;

UPDATE SuperStoreOrder
SET order_date_new = TRY_CONVERT(DATETIME,order_date,103);

ALTER TABLE SuperStoreOrder
DROP COLUMN order_date;
EXEC sp_rename 'SuperStoreOrder.order_date_new', 'order_date', 'COLUMN';

ALTER TABLE SuperStoreOrder ADD  ship_date_new DATETIME;
UPDATE SuperStoreOrder  SET SuperStoreOrder.ship_date_new = TRY_CONVERT(DATETIME, ship_date, 103);
ALTER TABLE SuperStoreOrder DROP COLUMN ship_date;
EXEC sp_rename "SuperStoreOrder.ship_date_new","ship_date", 'COLUMN';
SELECT * FROM SuperStoreOrder;

use learnsql;
ALTER TABLE dbo.SuperStoreOrder
ADD year_new INT

UPDATE SuperStoreOrder SET SuperStoreOrder.year_new = YEAR( TRY_CONVERT(INT,order_date,120) )

ALTER TABLE SuperStoreOrder
DROP COLUMN year

EXEC sp_rename 'SuperStoreOrder.year_new', 'year', 'COLUMN';

SELECT order_date, ship_date, year FROM SuperStoreOrder;



---========TESTING GROUND FOR REPORT
USE learnsql;

select * from [Date]

SELECT 
    d.year,
    SUM(s.sales) AS total_sales,
    SUM(s.profit) AS total_profit
FROM Sale s
JOIN Date d ON s.order_date = d.order_date
GROUP BY d.[year]