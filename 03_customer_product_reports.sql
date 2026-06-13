/*
==============================================================================
Reporting Views: gold.report_customers & gold.report_products
==============================================================================
Goal: turn everything from the EDA + advanced analytics steps into two
reusable views - one row per customer, one row per product - with the
key segmentation and KPI columns already calculated, so the rest of the
team (or a BI tool) can just query them directly.
==============================================================================
*/

-- ---------------------------------------------------------------------------
-- gold.report_products
-- ---------------------------------------------------------------------------
IF OBJECT_ID('gold.report_products', 'V') IS NOT NULL
    DROP VIEW gold.report_products;
GO

CREATE VIEW gold.report_products AS

WITH base_query AS (
-- base query: join sales with product info, drop rows with no order date
SELECT
f.order_number,
f.order_date,
f.customer_key,
f.sales_amount,
f.quantity,
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
WHERE order_date IS NOT NULL
)

-- per-product aggregations
, product_aggregation AS (
SELECT
product_key,
category,
subcategory,
product_name,
cost,
COUNT(DISTINCT order_number) total_orders,
SUM(sales_amount) total_sales,
SUM(quantity) total_quantity,
COUNT(DISTINCT customer_key) total_customers,
MAX(order_date) last_sale_date,
DATEDIFF(month, MIN(order_date), MAX(order_date)) lifespan,
ROUND(AVG(CAST(sales_amount AS FLOAT) / NULLIF(quantity, 0)), 1) avg_selling_price
FROM base_query
GROUP BY product_key, category, subcategory, product_name, cost
)

-- final output: combine aggregations + derived KPIs
SELECT
product_key,
product_name,
category,
subcategory,
cost,
last_sale_date,
DATEDIFF(month, last_sale_date, GETDATE()) recency_in_months,
CASE
  WHEN total_sales > 50000 THEN 'High-performer'
  WHEN total_sales >= 10000 THEN 'Mid-range'
  ELSE 'Low-performer'
END product_segment,
lifespan,
total_orders,
total_sales,
total_quantity,
avg_selling_price,
total_customers,
-- average order revenue
CASE WHEN total_orders = 0 THEN 0
  ELSE total_sales / total_orders
END avg_order_revenue,
-- average monthly revenue
CASE WHEN lifespan = 0 THEN total_sales
  ELSE total_sales / lifespan
END avg_monthly_revenue
FROM product_aggregation
GO


-- ---------------------------------------------------------------------------
-- gold.report_customers
-- ---------------------------------------------------------------------------
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO

CREATE VIEW gold.report_customers AS

WITH base_query AS (
-- base query: join sales with customer info, drop rows with no order date
SELECT
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ', c.last_name) customer_name,
c.birthdate,
DATEDIFF(year, c.birthdate, GETDATE()) age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key=c.customer_key
WHERE order_date IS NOT NULL
)

-- per-customer aggregations
, customer_aggregation AS (
SELECT
customer_key,
customer_number,
customer_name,
age,
COUNT(DISTINCT order_number) total_orders,
SUM(sales_amount) total_sales,
SUM(quantity) total_quantity,
COUNT(DISTINCT product_key) total_products,
MAX(order_date) last_order_date,
DATEDIFF(month, MIN(order_date), MAX(order_date)) lifespan
FROM base_query
GROUP BY customer_key, customer_number, customer_name, age
)

-- final output: combine aggregations + age groups + segments + KPIs
SELECT
customer_key,
customer_number,
customer_name,
age,
CASE
  WHEN age < 20 THEN 'Under 20'
  WHEN age BETWEEN 20 AND 29 THEN '20-29'
  WHEN age BETWEEN 30 AND 39 THEN '30-39'
  WHEN age BETWEEN 40 AND 49 THEN '40-49'
  ELSE '50 and above'
END age_group,
CASE
  WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
  WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
  ELSE 'New'
END customer_segment,
last_order_date,
DATEDIFF(month, last_order_date, GETDATE()) recency,
total_orders,
total_sales,
total_quantity,
total_products,
lifespan,
-- average order value
CASE WHEN total_orders = 0 THEN 0
  ELSE total_sales / total_orders
END avg_order_value,
-- average monthly spend
CASE WHEN lifespan = 0 THEN total_sales
  ELSE total_sales / lifespan
END avg_monthly_spend
FROM customer_aggregation
GO
