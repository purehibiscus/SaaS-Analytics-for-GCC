**Middle East SaaS Analytics Project (SQL)**

**Overview**

This project simulates a real-world analytics case for SaaS companies operating across the Middle East (GCC region). The objective was to transform messy, multisource data into a clean analytical model and generate business insights using SQL.

The project covers:
Data cleaning & standardization
Data modeling (raw → star schema)
Exploratory & advanced SQL analysis

**Dataset Description**

The project uses three synthetic but realistic datasets:
1.	Customers (`customers_me.csv`)
Customer demographics and acquisition details
Includes inconsistencies such as casing issues, null values, and duplicate categories

2.	Transactions (`transactions_me.csv`)
Revenue and payment data
Contains negative values, mixed currencies, and missing discounts

3.	Usage (`usage_me.csv`)
Customer engagement metrics
Includes nulls, text in numeric fields, and sparse behavioral data

**Data Cleaning**

Key cleaning steps performed: 
Standardized categorical fields using `LOWER()` and `TRIM()`

country
status
acquisition_channel
payment_method

Handled missing values:
Replaced nulls where appropriate
Flagged incomplete records for analysis

Fixed data quality issues:
Removed/adjusted negative transaction amounts
Converted mixed data types (e.g., "N/A" → NULL)
Normalized currency formats

**Data Modeling**

A star schema was built to support analytical queries.
 Fact Table
 `fact_transactions`
   transaction_id
   customer_id
   transaction_date
   amount_usd
   product_category
   discount_applied

 Dimension Tables
 `dim_customers`
   customer_id
   signup_date
   country
   industry
   customer_segment
   acquisition_channel

 `dim_usage`
   customer_id
   usage_date
   logins_count
   session_minutes
   support_tickets


Derived Features
Created analytical fields to support deeper insights:
 `cohort_month` → based on signup date
 `tenure_months` → customer lifetime in months
 `churn_flag` → based on inactivity and status
 Cleaned revenue metrics (discount-adjusted)

Analysis Performed
Revenue Analysis
Monthly revenue trends by country and industry
Revenue distribution across product categories
Impact of discounts on revenue

**Customer Segmentation**

Revenue contribution by customer segment (SME vs Enterprise)
Acquisition channel performance

**Churn Insights**

Churn rate by country and industry
Revenue lost due to churn
Relationship between support tickets and churn

**Customer Lifetime Value (LTV)**

Average LTV by country and industry
LTV comparison across customer segments
High vs low engagement user value

**Behavioral Insights**

Repeat transaction patterns
Engagement vs revenue relationship
Support activity trends

**SQL Techniques Used**

Common Table Expressions (CTEs)
Joins (INNER, LEFT)
Window Functions (`LAG`, `ROW_NUMBER`)
Date functions (`DATE_TRUNC`, `DATEDIFF`)
Conditional aggregation
Cohort analysis logic

**Key Insights**

A small percentage of customers contribute the majority of revenue (Pareto effect)
Enterprise customers generate significantly higher LTV than SMEs
High engagement (logins & sessions) strongly correlates with retention
Certain acquisition channels yield higher-quality customers
Churn is often preceded by a drop in usage and increased support tickets

**Project Outcome**

This project demonstrates the ability to:
Clean and prepare messy real-world data
Design scalable analytical data models
Apply SQL to solve business problems
Generate actionable insights from raw datasets

**Tools Used**

SQL (MS SQL Server/ TSQL / PostgreSQL compatible)
Excel / CSV datasets


