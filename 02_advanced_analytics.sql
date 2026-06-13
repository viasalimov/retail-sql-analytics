/*
==============================================================================
Advanced Analytics
==============================================================================
Goal: go from "what are the numbers" (EDA) to "how are things changing,
who matters most, and how do I group things that aren't natural dimensions".

Covers:
  - change over time (trend analysis)
  - cumulative analysis (running totals, moving averages)
  - performance analysis (YoY vs average, vs previous year)
  - part-to-whole analysis
  - data segmentation (products by cost, customers by spend/lifespan)
==============================================================================
*/

-- ---------------------------------------------------------------------------
-- 1. Change over time analysis
-- same question (sales/customers/quantity per period), 3 ways of getting
-- there - quick date parts, DATETRUNC, and FORMAT
-- ---------------------------------------------------------------------------

-- quick date functions: year + month columns
SELECT
YEAR(order_date) order_year,
MONTH(order_date) order_month,
SUM(sales_amount) total_revenue,
COUNT(DISTINCT customer_key) total_customers,
SUM(quantity) total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date)

-- DATETRUNC - cleaner grouping by year
SELECT
DATETRUNC(year, order_date) order_month,
SUM(sales_amount) total_revenue,
COUNT(DISTINCT customer_key) total_customers,
SUM(quantity) total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(year, order_date)
ORDER BY DATETRUNC(year, order_date)

-- FORMAT - human-readable "yyyy-MMM" labels, handy for charts
SELECT
FORMAT(order_date, 'yyyy-MMM') order_month,
SUM(sales_amount) total_revenue,
COUNT(DISTINCT customer_key) total_customers,
SUM(quantity) total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY FORMAT(order_date, 'yyyy-MMM')
ORDER BY FORMAT(order_date, 'yyyy-MMM')


-- ---------------------------------------------------------------------------
-- 2. Cumulative analysis
-- running total of sales + moving average price, month by month
-- ---------------------------------------------------------------------------

SELECT
order_date,
total_sales,
SUM(total_sales) OVER (PARTITION BY YEAR(order_date) ORDER BY order_date) running_total_sales,
AVG(avg_price) OVER (ORDER BY order_date) moving_avg_price
FROM (
SELECT
DATETRUNC(month, order_date) order_date,
SUM(sales_amount) total_sales,
AVG(price) avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month, order_date)
) t


-- ---------------------------------------------------------------------------
-- 3. Performance analysis (YoY)
-- compare current value to a target (avg / previous year) to measure
-- whether performance is improving or not
-- ---------------------------------------------------------------------------

WITH yearly_product_sales AS (
SELECT
YEAR(f.order_date) order_year,
p.product_name,
SUM(f.sales_amount) current_year_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON f.product_key=p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY YEAR(f.order_date), p.product_name
)
SELECT
order_year,
product_name,
current_year_sales,
AVG(current_year_sales) OVER (PARTITION BY product_name) avg_sales,
current_year_sales - AVG(current_year_sales) OVER (PARTITION BY product_name) diff_vs_avg,
CASE
  WHEN current_year_sales - AVG(current_year_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
  WHEN current_year_sales - AVG(current_year_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
  ELSE 'Avg'
END avg_change,
-- year-over-year comparison
LAG(current_year_sales) OVER (PARTITION BY product_name ORDER BY order_year) prev_year_sales,
current_year_sales - LAG(current_year_sales) OVER (PARTITION BY product_name ORDER BY order_year) diff_vs_prev_year,
CASE
  WHEN current_year_sales - LAG(current_year_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
  WHEN current_year_sales - LAG(current_year_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
  ELSE 'No change'
END prev_year_change
FROM yearly_product_sales
ORDER BY product_name, order_year


-- ---------------------------------------------------------------------------
-- 4. Part-to-whole analysis
-- which categories make up how much of total revenue?
-- ---------------------------------------------------------------------------

WITH category_sales AS (
SELECT
category,
SUM(sales_amount) total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key=f.product_key
GROUP BY category
)
SELECT
category,
total_sales,
SUM(total_sales) OVER () overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER ()) * 100, 2), '%') pct_of_total
FROM category_sales
ORDER BY total_sales DESC


-- ---------------------------------------------------------------------------
-- 5. Data segmentation
-- group records into buckets when dimensions alone aren't enough
-- ---------------------------------------------------------------------------

-- products grouped by cost range
WITH product_segments AS (
SELECT
product_key,
product_name,
cost,
CASE
  WHEN cost < 100 THEN 'Below 100'
  WHEN cost BETWEEN 100 AND 500 THEN '100-500'
  WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
  ELSE 'Above 1000'
END cost_range
FROM gold.dim_products
)
SELECT
cost_range,
COUNT(product_key) total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC

-- customers grouped by spend + lifespan
-- VIP: 12+ months active and total spend > 5000
-- Regular: 12+ months active, spend <= 5000
-- New: less than 12 months active
WITH customer_spending AS (
SELECT
c.customer_key,
SUM(f.sales_amount) total_spending,
MIN(order_date) first_order,
MAX(order_date) last_order,
DATEDIFF(month, MIN(order_date), MAX(order_date)) customer_lifespan
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON f.customer_key=c.customer_key
GROUP BY c.customer_key
)
SELECT
customer_segment,
COUNT(customer_key) number_of_customers
FROM (
SELECT
customer_key,
CASE
  WHEN customer_lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
  WHEN customer_lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
  ELSE 'New'
END customer_segment
FROM customer_spending
) t
GROUP BY customer_segment
ORDER BY number_of_customers DESC
