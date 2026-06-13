# Retail Sales SQL Analytics (T-SQL)

A SQL-based analysis of a bike retailer's sales data — exploring the customer base, product catalog, and sales transactions to understand revenue drivers, customer value, and trends over time. Written in T-SQL (SQL Server).

## Why this project

I wanted to combine EDA-style exploration (what does the data even look like?) with more advanced techniques — window functions, running totals, year-over-year comparisons, and segmentation — and packaging the results into reusable reporting views.

## Dataset

A small star-schema retail dataset (`gold` layer):

- **dim_customers** — 18,484 customers (country, gender, birthdate, etc.)
- **dim_products** — 295 products (category, subcategory, cost, product line)
- **fact_sales** — 60,398 sales line items (Dec 2010 – Jan 2014)

## What's in the analysis

### `01_eda_exploration.sql`
Getting to know the data before doing anything else:
- Database/schema exploration (`INFORMATION_SCHEMA`)
- Dimension exploration (unique countries, categories, subcategories)
- Date range exploration (order date range, customer age range)
- Measures exploration (total sales, quantity, avg price, orders, products, customers — combined into one summary report)
- Magnitude analysis (revenue/customers broken down by country, gender, category)
- Ranking analysis — Top N / Bottom N products and customers, using both `TOP` and `RANK()`/`DENSE_RANK()` window functions

### `02_advanced_analytics.sql`
- **Change over time** — monthly sales/customers/quantity using `YEAR()`/`MONTH()`, `DATETRUNC()`, and `FORMAT()`
- **Cumulative analysis** — running total of sales and moving average price using `SUM() OVER()` / `AVG() OVER()`
- **Performance analysis (YoY)** — each product's yearly sales vs. its own average and vs. the previous year, using `LAG()` and `CASE`
- **Part-to-whole analysis** — each category's share of total revenue using `SUM() OVER()`
- **Segmentation** — products bucketed by cost range, customers bucketed into VIP / Regular / New based on spend and lifespan

### `03_customer_product_reports.sql`
Two reusable views that pull everything together:
- **`gold.report_products`** — one row per product with total orders/sales/quantity, recency, lifespan, average order revenue, average monthly revenue, and a High/Mid/Low performer segment
- **`gold.report_customers`** — one row per customer with age group, VIP/Regular/New segment, recency, lifespan, average order value, and average monthly spend

## Key Findings

- **Bikes dominate revenue**: \~96.5% of total sales (\~$29.4M) come from the Bikes category — Accessories and Clothing combined are under 4%.
- **Road Bikes is the single biggest subcategory**, generating \~$14.5M (about half of all revenue), followed by Mountain Bikes (\~$10.0M).
- **Customer base skews "New"**: of 18,484 customers, \~79% fall into the New segment (under 12 months of activity), \~12% are Regular, and \~9% are VIP — suggesting retention/repeat-purchase is an area worth digging into further.
- Sales data spans **Dec 2010 – Jan 2014**, giving enough history for meaningful YoY and cumulative trend analysis.

## Repository Structure

```
retail-sql-analytics/
├── README.md
├── 00_setup.sql
├── 01_eda_exploration.sql
├── 02_advanced_analytics.sql
├── 03_customer_product_reports.sql
└── datasets/
    ├── gold.dim_customers.csv
    ├── gold.dim_products.csv
    └── gold.fact_sales.csv
```

## How to Run

These scripts are written in **T-SQL** and were run on **SQL Server** (e.g. via SQL Server Management Studio or Azure Data Studio).

1. Download this repo and note the path to the `datasets/` folder
2. Open `00_setup.sql`, update the `BULK INSERT` file paths to point to your local `datasets/` folder, and run it — this creates the `gold` schema with `dim_customers`, `dim_products`, and `fact_sales`, and loads them from the CSVs
3. Run `01_eda_exploration.sql` for the exploration queries
4. Run `02_advanced_analytics.sql` for trend, cumulative, performance, and segmentation queries
5. Run `03_customer_product_reports.sql` to create the `gold.report_customers` and `gold.report_products` views

The dataset is a small star-schema retail dataset — \~18K customers, \~300 products, \~60K sales records (Dec 2010 – Jan 2014).

