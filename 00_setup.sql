/*
==============================================================================
Setup: create the gold schema tables and load the CSV data
==============================================================================
Run this first. It creates the three tables used by all the other scripts
and loads them from the CSV files in /datasets.

Adjust the file paths in BULK INSERT to wherever you put the CSVs locally.
==============================================================================
*/

CREATE SCHEMA gold;
GO

CREATE TABLE gold.dim_customers (
customer_key INT,
customer_id INT,
customer_number NVARCHAR(50),
first_name NVARCHAR(50),
last_name NVARCHAR(50),
country NVARCHAR(50),
marital_status NVARCHAR(50),
gender NVARCHAR(50),
birthdate DATE,
create_date DATE
);
GO

CREATE TABLE gold.dim_products (
product_key INT,
product_id INT,
product_number NVARCHAR(50),
product_name NVARCHAR(50),
category_id NVARCHAR(50),
category NVARCHAR(50),
subcategory NVARCHAR(50),
maintenance NVARCHAR(50),
cost INT,
product_line NVARCHAR(50),
start_date DATE
);
GO

CREATE TABLE gold.fact_sales (
order_number NVARCHAR(50),
product_key INT,
customer_key INT,
order_date DATE,
shipping_date DATE,
due_date DATE,
sales_amount INT,
quantity TINYINT,
price INT
);
GO

-- load the data (update the paths below to match your local folder)
BULK INSERT gold.dim_customers
FROM 'C:\path\to\datasets\gold.dim_customers.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
GO

BULK INSERT gold.dim_products
FROM 'C:\path\to\datasets\gold.dim_products.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
GO

BULK INSERT gold.fact_sales
FROM 'C:\path\to\datasets\gold.fact_sales.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', TABLOCK);
GO
