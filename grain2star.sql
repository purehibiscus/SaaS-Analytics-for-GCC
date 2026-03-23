USE lb_salesDB
GO

CREATE SCHEMA dim;

CREATE TABLE [lb_salesDB].[dim].[customer] (
	customer_key INT,
	customer_id NVARCHAR(20),
	signup_date DATE,
	industry NVARCHAR(50),
	customer_segment NVARCHAR(50),
	cust_status NVARCHAR(20),
	acquisition_channel NVARCHAR(50),
	country NVARCHAR(50)
	);

-- Dim_customer
INSERT INTO [lb_salesDB].[dim].[customer] (customer_key, customer_id, signup_date, industry, 
											 customer_segment, cust_status, acquisition_channel, country)
SELECT 
	customer_key,
	customer_id,
	signup_date,
	industry,
	customer_segment,
	cust_status,
	acquisition_channel,
	country
FROM #temp_2b

UPDATE [lb_salesDB].[dim].[customer]
SET customer_key =  #temp_2b.customer_key
FROM #temp_2b
WHERE #temp_2b.customer_id = #temp_2b.customer_id


SELECT TOP(10) *
FROM [lb_salesDB].[dim].[customer]


-- Dim_country
CREATE TABLE [lb_salesDB].[dim].[country] (
	country_key INT,
	cleaned_country_name NVARCHAR(20),
	country NVARCHAR(20)
	);


INSERT INTO [lb_salesDB].[dim].[country] (country_key, cleaned_country_name, country)
SELECT 
	DENSE_RANK() OVER(ORDER BY c.cleaned_country_name) AS country_key,
	c.cleaned_country_name,
	c.country
FROM [lb_salesDB].[dbo].[customers_me] c

-- Dim_industry
CREATE TABLE [lb_salesDB].[dim].[industry] (
	industry_key INT,
	cleaned_industry NVARCHAR(20)
	);

INSERT INTO [lb_salesDB].[dim].[industry] (industry_key, cleaned_industry)
SELECT 
	DENSE_RANK() OVER(ORDER BY c.cleaned_industry) AS industry_key,
	c.cleaned_industry
FROM [lb_salesDB].[dbo].[customers_me] c

-- Dim_segment
CREATE TABLE [lb_salesDB].[dim].[segment] (
	segment_key INT,
	cleaned_customer_segment NVARCHAR(20)
	);


INSERT INTO [lb_salesDB].[dim].[segment] (segment_key, cleaned_customer_segment)

SELECT
	DENSE_RANK() OVER (ORDER BY c.cleaned_customer_segment) AS segment_key,
	c.cleaned_customer_segment
FROM [lb_salesDB].[dbo].[customers_me] c

-- Dim_product
CREATE TABLE [lb_salesDB].[dim].[product] (
	product_key INT,
	cleaned_product NVARCHAR(20)
	);

INSERT INTO [lb_salesDB].[dim].[product] (product_key, cleaned_product)
SELECT
	DENSE_RANK() OVER (ORDER BY t.cleaned_product) AS product_key,
	t.cleaned_product
FROM [lb_salesDB].[dbo].[transactions_me] t


-- Dim_paymentMethod
CREATE TABLE [lb_salesDB].[dim].[paymentMethod] (
	payment_key INT,
	payment_method NVARCHAR(20),
	revenue FLOAT
	);

INSERT INTO [lb_salesDB].[dim].[paymentMethod] (payment_key, payment_method, revenue)

SELECT 
	DENSE_RANK() OVER (ORDER BY t.payment_method) AS payment_key,
	payment_method,
	revenue
FROM (
	SELECT 
		t.payment_method,
		ROUND(ABS(COALESCE(SUM(t.amount_usd * (1 - t.discount_applied) * t.fixed_FX_rates), 0)), 2) revenue
	FROM [lb_salesDB].[dbo].[transactions_me] t
	GROUP BY 
		t.payment_method,
		t.fixed_FX_rates,
		t.discount_applied
	)t

-- Dim_date
CREATE TABLE [lb_salesDB].[dim].[date] (
	transac_date_key INT,
	cleaned_transaction_date DATE,
	transac_year INT,
	transac_month INT,
	transac_day INT,
	cleaned_usage_date DATE,
	usage_month INT,
	signup_date DATE,
	signup_year INT,
	signup_month INT,
	derived_cohort_month INT,
	cohort_month_name NVARCHAR(50),
	cohort_count_perMonth INT
	);

	
INSERT INTO [lb_salesDB].[dim].[date] 
	(transac_date_key, cleaned_transaction_date, transac_year, transac_month, 
		transac_day, cleaned_usage_date, usage_month, signup_date, signup_year, signup_month, 
		derived_cohort_month, cohort_month_name, cohort_count_perMonth)

SELECT
	DENSE_RANK() OVER (ORDER BY t.transaction_date) AS transac_date_key,
	t.cleaned_transaction_date,
	YEAR(t.cleaned_transaction_date) AS transac_year,
	MONTH(t.cleaned_transaction_date) AS transac_month,
	DAY(t.cleaned_transaction_date) AS transac_day,
	u.cleaned_usage_date,
	MONTH(u.cleaned_usage_date) AS usage_month,
	c.signup_date,
	YEAR(c.signup_date) signup_year,
	MONTH(c.signup_date) AS signup_month,
	DATEPART(MONTH, c.signup_date) derived_cohort_month,
	DATENAME(MONTH, c.signup_date) cohort_month_name,
	COUNT(t.transaction_date) OVER(PARTITION BY YEAR(c.signup_date), DATEPART(MONTH, signup_date) 
										ORDER BY YEAR(c.signup_date) ASC) cohort_count_perMonths
FROM [lb_salesDB].[dbo].[transactions_me] t	
LEFT JOIN [lb_salesDB].[dbo].[usage_me] u
ON t.customer_id = u.customer_id
LEFT JOIN [lb_salesDB].[dbo].[customers_me] c
ON t.customer_id = c.customer_id

-- Fact_transactions
USE lb_salesDB
GO

CREATE SCHEMA fact;


CREATE TABLE [lb_salesDB].[fact].[transactions] (
	transaction_key INT,
	currency_key INT,
	customer_key INT,
	product_key INT,
	industry_key INT,
	country_key INT,
	payment_key INT,
	transac_date_key INT,
	FX_rate FLOAT,
	transaction_amount FLOAT,
	discount INT
	);

	 
INSERT INTO [lb_salesDB].[fact].[transactions] 
	(transaction_key, currency_key, customer_key, product_key, industry_key, country_key, payment_key, 
		transac_date_key, FX_rate, transaction_amount, discount)
 
SELECT
	DENSE_RANK() OVER (ORDER BY t.transaction_id) AS transaction_key,
	DENSE_RANK() OVER (ORDER BY t.currency) AS currency_key,
	DENSE_RANK() OVER (ORDER BY c.customer_id) AS customer_key,
	DENSE_RANK() OVER (ORDER BY t.product_category) AS product_key,
	DENSE_RANK() OVER (ORDER BY c.cleaned_industry) AS industry_key,
	DENSE_RANK() OVER (ORDER BY c.cleaned_country_name) AS country_key,
	DENSE_RANK() OVER (ORDER BY t.payment_method) AS payment_key,
	DENSE_RANK() OVER (ORDER BY t.transaction_date) AS transac_date_key,
	ROUND(t.fixed_FX_rates, 2) FX_rate,
	ABS(t.amount_usd) transaction_amount,
	t.discount_applied discount
FROM [lb_salesDB].[dbo].[transactions_me] t	
LEFT JOIN [lb_salesDB].[dbo].[customers_me] c
ON t.customer_id = c.customer_id

 


-- Fact_Usage
CREATE TABLE [lb_salesDB].[fact].[usage] (
	usage_key INT,
	customer_key INT,
	u_date_key INT,
	product_id INT,
	cleaned_usage_date DATE,
	logins_count INT,
	features_used INT NULL,
	cleaned_session_minutes FLOAT NULL,
	support_tickets INT NULL
	);

INSERT INTO [lb_salesDB].[fact].[usage] 
	(usage_key, customer_key, u_date_key, product_id, cleaned_usage_date, logins_count, features_used, cleaned_session_minutes, support_tickets)

SELECT
	DENSE_RANK() OVER (ORDER BY u.usage_id) AS usage_key,
	DENSE_RANK() OVER (ORDER BY c.customer_id) AS customer_key,
	DENSE_RANK() OVER (ORDER BY u.cleaned_usage_date) AS u_date_key,
	DENSE_RANK() OVER (ORDER BY t.cleaned_product) AS product_id,
	u.cleaned_usage_date,
	u.logins_count,
	u.features_used,
	u.cleaned_session_minutes,
	u.support_tickets
FROM [lb_salesDB].[dbo].[usage_me] u	
LEFT JOIN [lb_salesDB].[dbo].[customers_me] c
ON u.customer_id = c.customer_id
LEFT JOIN [lb_salesDB].[dbo].[transactions_me] t
ON u.customer_id = t.customer_id

-- dim_FX_Rates
CREATE TABLE [lb_salesDB].[dim].[FX_rates] (
	currency_key INT,
	currency NVARCHAR(10),
	fixed_FX_rates FLOAT
	);

INSERT INTO [lb_salesDB].[dim].[FX_rates] (currency_key, currency, fixed_FX_rates)
SELECT
	DENSE_RANK() OVER (ORDER BY t.currency) as currency_key,
	t.currency,
	t.fixed_FX_rates
FROM [lb_salesDB].[dbo].[transactions_me] t	

SELECT *
FROM [lb_salesDB].[dim].[FX_rates]
