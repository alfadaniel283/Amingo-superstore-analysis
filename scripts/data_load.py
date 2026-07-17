import pandas as pd
from sqlalchemy import create_engine, Table, MetaData, Column, Integer, String, Float, DateTime
from sqlalchemy.engine import URL
import pyodbc
import traceback


# ── 1. Connection properties ───────────────────────────────────────────────
connection_properties = (
    r'DRIVER={FreeTDS};'
    r'SERVER=localhost, 1433;'
    r'DATABASE=AmingoStore;'
    r'UID=sa;'
    r'PWD=Lumanlee1234;'
    r'TrustServerCertificate=yes;'
);

# ── 2. Test  pyodbc connection ──────────────────────────────────────────
print("================> testing connecetions<============================")
conn = pyodbc.connect(connection_properties)
cursor= conn.cursor()
print("connection established........interacting with the server.......exiting")


# ── 3. Build SQLAlchemy engine (only once) ─────────────────────────────────
connection_url = URL.create(
    "mssql+pyodbc",
    query={"odbc_connect": connection_properties}
)

print("===========================> initializing DB engine.......")
engine = create_engine(connection_url, fast_executemany=False)



# ── 4. Read CSV ────────────────────────────────────────────────────────────
print("===============> Reading csv file from ./ directory <===========================")

file_path = '/home/klein/superstor_project/SuperStoreOrders.csv'
table_name='StoreOrder'

df = pd.read_csv(
    file_path,
    encoding='utf-8-sig',
    thousands=',',
    dayfirst=False
)

print(f"===============> File read successfully. Shape: {df.shape}")


# ── 5. Clean column names ────────────────────────────────────────────────
##displaying changes done to data
print(".......done")
print(df.dtypes)
print(f"Rows: {len(df)}")
print(df.head(3))


#creating tables in sql server
superstoreorder = """
IF OBJECT_ID('dbo.StoreOrder', 'U') IS NOT NULL
    DROP TABLE dbo.StoreOrder;

    CREATE TABLE StoreOrder(
        order_id NVARCHAR(50) NOT NULL,
        order_date NVARCHAR(100) NOT NULL,
        ship_date  NVARCHAR(100) NULL,
        ship_mode NVARCHAR(50) NOT NULL,
        customer_name NVARCHAR(300) NOT NULL,
        segment NVARCHAR(50) NOT NULL,
        state NVARCHAR(50) NOT NULL,
        country NVARCHAR(50) NOT NULL,
        market NVARCHAR(50) NOT NULL,
        region NVARCHAR(50) NOT NULL,
        product_id NVARCHAR(50) NOT NULL,
        category NVARCHAR(100) NOT NULL,
        sub_category NVARCHAR(100) NOT NULL,
        product_name NVARCHAR(300) NOT NULL,
        sales INT NOT NULL,
        quantity INT NOT NULL,
        discount DECIMAL NOT NULL,
        profit DECIMAL NOT NULL,
        shipping_cost DECIMAL NOT NULL,
        order_priority NVARCHAR(50) NOT NULL,
        year INT NOT NULL
    );
"""
cursor.execute(superstoreorder)
conn.commit()
print('==========SuperStoreOrder table has been created======================')



# ── 6. Upload to SQL Server ───────────────────────────────────────────────
print("=================> Uploading DataFrame to database====================")
try:

    df.to_sql(
        name=table_name,
        con=engine,
        schema="dbo",
        chunksize=2100 // len(df.columns),
        method=None,
        index=False,
        if_exists='append'
    )
    print(f"success: {len(df)} row inserted into {table_name}")

except TypeError as name_er:
    print(f"some columns names mismatches at {name_er}")


except Exception as e:
    print("===== FULL ERROR =====")
    print(type(e))           # tells us the exact exception class
    print(str(e))            # full error message
    traceback.print_exc()    # full stack trace
    print("===== DTYPES =====")
    print(df.dtypes)         # shows us column types pandas is using
    print("===== NULL COUNTS =====")
    print(df.isnull().sum()) 

####Function for executing sql commmands======
def executesql(script):
    try:
        cursor.execute(script)
        conn.commit()

    except Exception as err:
        print("Error message:", err)

    print(f"{script} has been executed successfully")


##Fixing Date datatype
order_ship_date_new_col = """
ALTER TABLE StoreOrder ADD  ship_date_new DATETIME;

ALTER TABLE StoreOrder ADD  order_date_new DATETIME;

"""
order_ship_date = """
USE AmingoStore;


UPDATE StoreOrder  SET StoreOrder.ship_date_new = TRY_CONVERT(DATETIME, ship_date, 103);
ALTER TABLE StoreOrder DROP COLUMN ship_date;
EXEC sp_rename "StoreOrder.ship_date_new","ship_date", 'COLUMN';


UPDATE StoreOrder  SET StoreOrder.order_date_new = TRY_CONVERT(DATETIME, order_date, 103);
ALTER TABLE StoreOrder DROP COLUMN order_date;
EXEC sp_rename "StoreOrder.order_date_new","order_date", 'COLUMN';

"""


print("Altering Order_date and ship_date column to fix datetype")
print('creating new tables')


executesql(order_ship_date_new_col)
executesql(order_ship_date)



