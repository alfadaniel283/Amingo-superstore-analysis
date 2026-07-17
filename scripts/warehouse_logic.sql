Use learnsql;



--========================================================================
PRINT '=============STARTING TABLE NORMALIZATION, USING STAR SCHEMA STRUCTURE================='
--========================================================================

PRINT '==============BEGINNING TABLE CREATION OPERATION===================='

PRINT '===============CREATE PRODUCT TABLE==============='
IF OBJECT_ID('dbo.Product', 'U') IS  NULL

    CREATE TABLE Product(
        product_id  NVARCHAR(50) NOT NULL PRIMARY KEY,
        product_name    NVARCHAR(300) NOT NULL,
        category    NVARCHAR(100) NOT NULL,
        sub_category NVARCHAR(100) NOT NULL
    );


PRINT '================CREATE CUSTOMER TABLE==================='
IF OBJECT_ID('dbo.Customer', 'U') IS NULL

    CREATE TABLE Customer(
        customer_id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
        customer_name  NVARCHAR(300) NOT NULL,
        segment        NVARCHAR(50) NOT NULL
    );


PRINT '==========CREATE LOCATION TABLE=========================='
IF OBJECT_ID('dbo.Location', 'U') IS NULL
   
    CREATE TABLE Location(
        location_id INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
        [state] NVARCHAR(50) NOT NULL,
        country NVARCHAR(50)  NOT NULL,
        market NVARCHAR(50) NOT NULL,
        region NVARCHAR(50) NOT NULL
    );


PRINT '=========ORDER_INFO============='
IF OBJECT_ID('Order_info', 'U') IS NULL
    CREATE TABLE Order_info(
        order_id NVARCHAR(50) NOT NULL PRIMARY KEY,
        ship_mode NVARCHAR(50) NOT NULL,
        order_priority NVARCHAR(50) NOT NULL
    );

PRINT '============CREATE DATE TABLE====================='
IF OBJECT_ID('Date', 'U') IS NULL
    CREATE TABLE Date(
        order_date DATETIME NOT NULL PRIMARY KEY,
        ship_date DATETIME NOT NULL,
        year   INT NOT NULL
    );


PRINT '============ CREATE SALE TABLE================='

IF OBJECT_ID('dbo.Sale', 'U') IS NULL
    CREATE TABLE Sale(
        order_id NVARCHAR(50) NOT NULL,
        customer_name NVARCHAR(300) NOT NULL,
        product_id NVARCHAR(50) NOT NULL,
        location_id INT NOT NULL,
        order_date DATETIME NOT NULL,
        sales INT NOT NULL,
        quantity INT NOT NULL,
        discount DECIMAL NOT NULL,
        profit DECIMAL NOT NULL,
        ship_cost DECIMAL NOT NULL
    );

PRINT '============TABLE CREATION COMPLETED==============='
PRINT '==============CREATING FOREIGN KEY CONSTRAINT===================='

---==================DEFINE KEY CONSTRAINS=================

ALTER TABLE dbo.Sale ADD CONSTRAINT FK_SALE_ORDER_INFO FOREIGN KEY (order_id) REFERENCES Order_info(order_id);
PRINT 'SALES HAS BEEN BINDED TO ORDER_INFO AS FK_SALE_ORDER_INFO'

ALTER TABLE dbo.Sale ADD CONSTRAINT FK_SALE_CUSTOMER FOREIGN KEY (customer_id) REFERENCES Customer(customer_id);
PRINT 'SALES HAS BEEN BINDED TO CUSTOMER AS FK_SALE_CUSTOMER'

ALTER TABLE dbo.Sale ADD CONSTRAINT FK_SALE_PRODUCT FOREIGN KEY (product_id) REFERENCES Product(product_id);
PRINT 'SALES HAS BEEN BINDED TO PRODUCT AS FK_SALE_PRODUCT'

ALTER TABLE dbo.Sale ADD CONSTRAINT FK_SALE_LOCATION FOREIGN KEY (location_id) REFERENCES [Location](location_id);
PRINT 'SALES HAS BEEN BINDED TO LOCATION AS FK_SALE_LOCATION'
ALTER TABLE dbo.Sale ADD CONSTRAINT FK_SALE_DATE FOREIGN KEY (order_date) REFERENCES [DATE](order_date);
PRINT 'SALES HAS BEEN BINDED TO ODATE AS FK_SALE_DATE'

PRINT '============FOREIGN KEYS CREATION COMPLETED============='

PRINT '==========INITIATING DATA LOADING TO CREATED TABLE =================='

PRINT '==================LOADING PRODUCT DATA============='
BEGIN TRY
    BEGIN TRANSACTION
        INSERT INTO Product(product_id, product_name, category, sub_category)
            SELECT DISTINCT 
                product_id, 
                FIRST_VALUE(product_name) OVER (PARTITION BY product_id ORDER BY product_id),
                FIRST_VALUE(category) OVER (PARTITION BY product_id ORDER BY product_id),
                FIRST_VALUE(sub_category) OVER (PARTITION BY product_id ORDER BY product_id)
            FROM [dbo].[SuperStoreOrder]
            WHERE product_id IS NOT NULL
            AND product_id NOT IN (SELECT product_id FROM Product);

    COMMIT TRANSACTION
             PRINT '************PRODUCT DATA LOADING COMPLETTED______INITIALIZING CUSTOMER DATA LOADING =========='
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
    PRINT 'Erorr:' + ERROR_MESSAGE();

END CATCH;

--=========================Customer Table=======================
BEGIN TRY
    BEGIN TRANSACTION

        INSERT INTO Customer(customer_name, segment)
            SELECT DISTINCT 
                [customer_name],
                [segment]
            FROM [dbo].[SuperStoreOrder];

    COMMIT TRANSACTION
    PRINT '************* CUSTOMER DATA LOADING COMPLETED_______INITIALIZING LOCATION TABLE============= '
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
        PRINT 'Error:' + ERROR_MESSAGE();
END CATCH;


---============Location Table======================
BEGIN TRY
    BEGIN TRANSACTION
        INSERT INTO [Location]([state], country, market, region)
            SELECT DISTINCT 
                [state], 
                [country], 
                [market], 
                [region] 
            FROM dbo.SuperStoreOrder;

    COMMIT TRANSACTION
    PRINT '*******LOCATION DATA COMPLETED______INITIALIZING ORDER_INFORMATION========'
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
    PRINT 'Error' + ERROR_MESSAGE();
END CATCH;
  

---============Order_Info Table======================
BEGIN TRY
    BEGIN TRANSACTION
        INSERT INTO Order_info(order_id, ship_mode, order_priority)
            SELECT DISTINCT 
                [order_id], 
                FIRST_VALUE([ship_mode]) OVER(PARTITION BY order_id ORDER BY order_id), 
                FIRST_VALUE([order_priority]) OVER(PARTITION BY order_id ORDER BY order_id) 
            FROM SuperStoreOrder
            WHERE [order_id] IS NOT NULL
            AND  [order_id] NOT IN (SELECT order_id FROM Order_Info)

    COMMIT TRANSACTION
    PRINT '*******ORDER_INFORMATION TABLE SETUP COMPLETED______ADVANCING TO DATE TABLE SETUP========'
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
        PRINT 'Error:' + ERROR_MESSAGE();
END CATCH


---============DATE Table======================
BEGIN TRY
    BEGIN TRANSACTION
        INSERT INTO [Date](order_date, ship_date, [year])
            SELECT DISTINCT 
                [order_date], 
                FIRST_VALUE([ship_date]) OVER(PARTITION BY [order_date] ORDER BY [order_date]), 
                FIRST_VALUE([year]) OVER(PARTITION BY [order_date] ORDER BY [order_date]) 
            FROM SuperStoreOrder
            WHERE [order_date] IS NOT NULL
            AND [order_date] NOT IN (SELECT [order_date] FROM [Date])

   COMMIT TRANSACTION
    PRINT '*******DATE TABLE SETUP COMPLETED_____CREATING FACT SALE========='
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
        PRINT 'Error:' + ERROR_MESSAGE();
END CATCH


---============SALE Table======================
BEGIN TRY
    BEGIN TRANSACTION
        INSERT INTO [Sale](order_id, customer_id, product_id, location_id, order_date, sales, quantity, discount, profit, ship_cost)
            SELECT DISTINCT 
                oi.[order_id],
                c.[customer_id],
                p.[product_id],
                l.[location_id],
                d.[order_date],
                sso.sales, sso.quantity, sso.discount, sso.profit, sso.ship_cost
            FROM SuperStoreOrder sso
            JOIN Order_Info oi ON sso.order_id = oi.order_id
            JOIN Customer c ON sso.customer_name = c.customer_name AND sso.segment = c.segment
            JOIN Product p ON sso.product_id  = p.product_id
            JOIN Location l ON  sso.state = l.[state] AND sso.country = l.country
            JOIN Date d ON sso.order_date = d.order_date;

   COMMIT TRANSACTION
    PRINT '*******COMPLETED FACT SALE TABLE:)(:'
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
        PRINT 'Error:' + ERROR_MESSAGE();
END CATCH
PRINT 'ALL DATA LOADED TO DATABASE, NORMALIZAtion COMPLETE'
