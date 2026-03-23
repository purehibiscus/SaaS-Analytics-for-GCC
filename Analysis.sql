--==================================
-- TIME-SERIES ANALYSIS
--==================================

-- What is the monthly revenue by country and industry?
WITH Monthly_industryRevenue AS ( 
	SELECT	
		DATENAME(MONTH, d.cleaned_transaction_date) month_name,
		c.cleaned_country_name country,
		i.cleaned_industry industry,
		SUM(t.transaction_amount * t.FX_rate)  transaction_amount,
		t.FX_rate conversion_to_dollar,
		t.discount
	FROM [lb_salesDB].[dim].[customer] cu
	LEFT JOIN [lb_salesDB].[dim].[date] d
	ON cu.signup_date = d.signup_date
	LEFT JOIN [lb_salesDB].[dim].[country] c
	ON cu.country = c.country
	LEFT JOIN [lb_salesDB].[dim].[industry] i
	ON cu.industry = i.cleaned_industry
	LEFT JOIN [lb_salesDB].[fact].[transactions] t
	ON cu.customer_key = t.customer_key
	GROUP BY DATENAME(MONTH, d.cleaned_transaction_date),
		c.cleaned_country_name,
		i.cleaned_industry
)
SELECT 
	month_name,
	country,
	industry,
	SUM(transaction_amount) total_amount
FROM Monthly_industryRevenue
GROUP BY 
	month_name,
	country,
	industry;


--==================================
-- TIME-SERIES ANALYSIS
--==================================

-- What is the monthly revenue by country and industry?
WITH Monthly_industryRevenue AS ( 
	SELECT	
		--CAST(d.cleaned_transaction_date AS DATE) transaction_date
		DATEPART(MONTH, CAST(d.cleaned_transaction_date AS DATE)) month_name,
		c.cleaned_country_name AS country,
		i.cleaned_industry AS industry,
		t.transaction_amount AS transaction_amount, 
		t.FX_rate 
	FROM [lb_salesDB].[dim].[customer] cu
	LEFT JOIN [lb_salesDB].[fact].[transactions] t
		ON cu.customer_key = t.customer_key
	LEFT JOIN [lb_salesDB].[dim].[date] d
		ON t.transac_date_key = d.cleaned_transaction_date
	LEFT JOIN [lb_salesDB].[dim].[country] c
		ON cu.country = c.country
	LEFT JOIN [lb_salesDB].[dim].[industry] i
		ON cu.industry = i.cleaned_industry
	WHERE d.cleaned_transaction_date = CONVERT(DATE, '20220101')
	
	GROUP BY
		DATENAME(MONTH, d.cleaned_transaction_date),
		c.cleaned_country_name,
		i.cleaned_industry
)

-- MoM & YoY growth Analysis 

-- Month over Month Analysis:
-- Short term trends and Seasonality
WITH MoM_Analysis AS (
	SELECT 
		d.cleaned_transaction_date transaction_date,
		t.transaction_amount,
		LEAD(d.cleaned_transaction_date) OVER (PARTITION BY DATEPART(MONTH, d.cleaned_transaction_date) 
																			ORDER BY d.cleaned_transaction_date) Next_transaction,
		DATEDIFF(MONTH, d.cleaned_transaction_date, LEAD(d.cleaned_transaction_date) 
						OVER (PARTITION BY DATEPART(MONTH, d.cleaned_transaction_date) 
								ORDER BY d.cleaned_transaction_date)) daysUntilNextTransaction
		
	 FROM [lb_salesDB].[dim].[date] d
	 LEFT JOIN [lb_salesDB].[fact].[transactions] t
	 ON d.transac_date_key = t.transac_date_key
)

SELECT 
	transaction_date,
	ROUND(transaction_amount, 2) transation_amount,
	Next_transaction, 
	daysUntilNextTransaction,
	AVG(daysUntilNextTransaction) AvgDays,
	RANK() OVER (ORDER BY AVG(daysUntilNextTransaction)) TransactionRanking
FROM MoM_Analysis
GROUP BY transaction_date, transaction_amount,
	Next_transaction, 
	daysUntilNextTransaction

--WHERE (Next_transaction > 0 AND daysUntilNextTransaction NOT NULL, AND AvgDays > 0)

-- YoY Analysis
WITH YoY_Analysis AS (
	SELECT 
		d.cleaned_transaction_date transaction_date,
		t.transaction_amount,
		LEAD(d.cleaned_transaction_date) OVER (PARTITION BY DATEPART(YEAR, d.cleaned_transaction_date) 
																			ORDER BY d.cleaned_transaction_date) Next_transaction,
		DATEDIFF(YEAR, d.cleaned_transaction_date, LEAD(d.cleaned_transaction_date) 
						OVER (PARTITION BY DATEPART(YEAR, d.cleaned_transaction_date) 
								ORDER BY d.cleaned_transaction_date)) daysUntilNextTransaction
		
	 FROM [lb_salesDB].[dim].[date] d
	 LEFT JOIN [lb_salesDB].[fact].[transactions] t
	 ON d.transac_date_key = t.transac_date_key
)

SELECT 
	transaction_date,
	ROUND(transaction_amount, 2) transation_amount,
	Next_transaction, 
	RANK() OVER (ORDER BY AVG(daysUntilNextTransaction)) TransactionRanking
FROM YoY_Analysis
GROUP BY transaction_date, transaction_amount,
	Next_transaction, 
	daysUntilNextTransaction

 FROM [lb_salesDB].[dim].[date]



 -- FInd the revenue volatility by product category
 -- Category resulting with high values would mean more of high ups and downs in the revenue, 
 -- while with categories with lower values will mean stable revenue.
 
WITH revenue_volatility AS (
	SELECT 
		p.cleaned_product product_category,
		DATEPART(YEAR, d.cleaned_transaction_date) transac_year,
		DATEPART(MONTH, d.cleaned_transaction_date) transac_month,
		DATENAME(MONTH, d.cleaned_transaction_date) month_name,
		ABS(SUM(t.transaction_amount * ( 1 - t.discount) * t.FX_rate)) revenue
	FROM [lb_salesDB].[fact].[transactions] t		
	LEFT JOIN [lb_salesDB].[dim].[product] p
	ON t.product_key = p.product_key
	LEFT JOIN [lb_salesDB].[dim].[date] d
	ON t.transac_date_key = d.transac_date_key
	
	GROUP BY 
		p.cleaned_product, 
		DATEPART(YEAR, d.cleaned_transaction_date), 
		DATEPART(MONTH, d.cleaned_transaction_date), 
		DATENAME(MONTH, d.cleaned_transaction_date)
	HAVING SUM(t.transaction_amount * t.discount * t.FX_rate) > 0	
)
 SELECT
	product_category,
	ROUND(STDEV(revenue), 2) revenue_stddev,
	ROUND(AVG(revenue), 2) avg_revenue,
	ROUND(STDEV(revenue) / AVG(revenue), 4) volatility
 FROM revenue_volatility
 GROUP BY product_category


 -- Find the impact of discounts on revenue overtime

SELECT 
	DATENAME(YEAR, d.cleaned_transaction_date) transaction_year,
	DATETRUNC(MONTH, d.cleaned_transaction_date) transaction_month,
	ROUND(SUM(t.transaction_amount * t.FX_rate), 2) total_revenue,
	ROUND(ABS(SUM(t.transaction_amount * (1 - t.discount))), 2) revenue_after_discount,
	ROUND(SUM(t.transaction_amount * t.discount), 2) lost_revenue_due_to_discount
FROM [lb_salesDB].[fact].[transactions] t
LEFT JOIN [lb_salesDB].[dim].[date] d
ON t.transac_date_key = d.transac_date_key
GROUP BY 
	DATENAME(YEAR, d.cleaned_transaction_date),
	DATETRUNC(MONTH, d.cleaned_transaction_date)
ORDER BY transaction_month;


-- Find the peak transaction periods across GCC countries.
-- GCC countries across this dataset are; Bahrain, Kuwait, Saudi Arabia, United Arab Emirates, Oman, and Qatar.

SELECT 
	DATEPART(YEAR, d.cleaned_transaction_date) transaction_year,
	c.cleaned_country_name country,
	FORMAT(ROUND(ABS(SUM(t.transaction_amount * (1 - t.discount) * t.fx_rate)), 2), 'N0') total_revenue,
	FORMAT(ROUND(ABS(SUM(t.transaction_amount * (1 - t.discount) * t.fx_rate)), 2), 'N0') total_revenue_formatted,
	DENSE_RANK() OVER 
			(PARTITION BY c.cleaned_country_name 
					ORDER BY ROUND(
								ABS(
									SUM(t.transaction_amount * (1 - t.discount) * t.fx_rate)), 2)) Country_Ranking
FROM [lb_salesDB].[dim].[country] c
LEFT JOIN [lb_salesDB].[fact].[transactions] t
ON c.country_key = t.country_key
LEFT JOIN [lb_salesDB].[dim].[date] d
ON t.transac_date_key = d.transac_date_key
GROUP BY 
	DATEPART(YEAR, d.cleaned_transaction_date),
	c.cleaned_country_name
ORDER BY 
	c.cleaned_country_name,
	DENSE_RANK() OVER ( ORDER BY ROUND(ABS(SUM(t.transaction_amount * (1 - t.discount) * t.fx_rate)), 2)),
	DATEPART(YEAR, d.cleaned_transaction_date)

--==================================
-- COHORT ANALYSIS
--==================================

-- What is the monthly customer acquisition and product usage overtime?
SELECT 
	t.customer_key,
	p.cleaned_product products,
	d.signup_date signup_date,
	d.cleaned_transaction_date transaction_date,
	u.cleaned_usage_date last_usage_date,
	u.cleaned_session_minutes total_session_minutes,
	DATEPART(YEAR, d.signup_date) signup_year,
	DATEPART(MONTH, d.signup_date) month_number,
	COUNT(d.signup_date) OVER 
							(PARTITION BY
								DATEPART(YEAR, d.signup_date), DATEPART(MONTH, d.signup_date) 
										ORDER BY DATEPART(YEAR, d.signup_date), DATEPART(MONTH, d.signup_date)) monthly_signed_ups,
	LEAD(d.signup_date) OVER 
							(PARTITION BY t.customer_key ORDER BY d.signup_date) current_signup_date,
	DATEDIFF(MONTH, d.signup_date, 
							LEAD(d.signup_date) OVER 
													(PARTITION BY t.customer_key ORDER BY d.signup_date)) Month_between_signups
FROM [lb_salesDB].[fact].[transactions] t
LEFT JOIN [lb_salesDB].[fact].[usage] u
ON t.customer_key = u.customer_key
LEFT JOIN [lb_salesDB].[dim].[date] d
ON t.transac_date_key = d.transac_date_key
LEFT JOIN [lb_salesDB].[dim].[product] p
ON t.product_key = p.product_key
WHERE 
	u.cleaned_session_minutes > 0
GROUP BY 
	t.customer_key,
	p.cleaned_product,
	d.signup_date,
	d.cleaned_transaction_date,
	u.cleaned_usage_date, 
	u.cleaned_session_minutes

-- Analyze customer loyalty by ranking customers based on the average number of days between signups?
SELECT 
	t.customer_key,
	AVG(Months_between_next_signup) Avg_Month,
	RANK() OVER (ORDER BY AVG(Months_between_next_signup)) signup_ranking
FROM (
	SELECT 
		t.transaction_key,
		t.customer_key,
		d.signup_date signup_date,
		LEAD(d.signup_date) OVER (PARTITION BY t.customer_key ORDER BY d.signup_date) next_signup,
		DATEDIFF(MONTH, d.signup_date, LEAD(d.signup_date) OVER (PARTITION BY t.customer_key ORDER BY d.signup_date)) Months_between_next_signup
	FROM [lb_salesDB].[fact].[transactions] t
	LEFT JOIN [lb_salesDB].[dim].[date] d
	ON t.transac_date_key = d.transac_date_key	
)t
GROUP BY 
		t.customer_key
HAVING AVG(Months_between_next_signup) > 0

-- Analyze customer usage session across product?
SELECT
    p.cleaned_product AS product_category,
    AVG(u.cleaned_session_minutes) AS avg_usage_minutes
FROM [lb_salesDB].[fact].[usage] u
LEFT JOIN [lb_salesDB].[dim].[product] p
    ON u.product_id = p.product_key
WHERE p.cleaned_product IS NOT NULL
GROUP BY p.cleaned_product
ORDER BY avg_usage_minutes DESC;

-- Analyze engagement decay patterns by cohort

SELECT 
   DATEPART(YEAR, u.signup_date) AS signup_year,
   DATEPART(QUARTER, u.signup_date) AS signup_quarter,
   FORMAT(ROUND(ABS(SUM(t.transaction_amount * (1 - t.discount) * t.fx_rate)), 2), 'N0') AS revenue,
   CONCAT(DATEPART(YEAR, u.signup_date), ' Q', DATEPART(QUARTER, u.signup_date)) AS customer_signup_cohort,
   DENSE_RANK() OVER (ORDER BY ROUND(ABS(SUM(t.transaction_amount * (1 - t.discount) * t.fx_rate)), 2)  DESC) cohort_ranking
FROM [lb_salesDB].[dim].[customer] u
LEFT JOIN [lb_salesDB].[fact].[transactions] t
ON u.customer_key = t.customer_key
GROUP BY
	DATEPART(YEAR, u.signup_date),
	DATEPART(QUARTER, u.signup_date)
ORDER BY 
	cohort_ranking


-- Analyze the comparison between SME vs Enterprise cohort retention.
SELECT 
    customer_segment,
    COUNT(*) AS signup_count
FROM [lb_salesDB].[dim].[customer]
WHERE customer_segment IN ('SME', 'Enterprise')
GROUP BY 
    customer_segment
ORDER BY 
    signup_count DESC;

-- Which acquisition channels create the strongest cohorts?

WITH acquisition_cohorts AS (
SELECT 
	acquisition_channel,
	COUNT(*) total_count
FROM [lb_salesDB].[dim].[customer]
GROUP BY acquisition_channel
)
SELECT 
	*,
	RANK() OVER (ORDER BY total_count DESC) acquisition_ranking
FROM acquisition_cohorts
ORDER BY total_count


--==================================
-- CUSTOMER CHURN ANALYSIS
--==================================

-- Analyze churn based on inactivity and status
SELECT 
	u.customer_key,
	u.logins_count,
	c.customer_active_status
FROM [lb_salesDB].[fact].[usage] u
LEFT JOIN [lb_salesDB].[dim].[customer] c
ON u.customer_key = c.customer_key
WHERE 
	c.customer_active_status IS NOT NULL
	AND c.customer_active_status  = 'churned'
GROUP BY u.logins_count, u.customer_key, c.customer_active_status

-- Analyze churn rate by industry and country
SELECT
	country,
	industry,
	cust_status,
	COUNT(*) churn_rate
FROM [lb_salesDB].[dim].[customer]
WHERE cust_status = 'churned'
GROUP BY country, industry, cust_status
ORDER BY country, churn_rate DESC

-- Analyze customer engagement patterns 30-60 days before churn
SELECT
	c.customer_segment,
	c.cust_status,
	c.signup_date,
	u.logins_count, 
	DATEDIFF(DAY, LAG(c.signup_date) OVER (ORDER BY c.signup_date), c.signup_date) days_before_churn
FROM [lb_salesDB].[dim].[customer] c
LEFT JOIN [lb_salesDB].[fact].[usage] u
ON c.customer_key = u.customer_key
WHERE c.cust_status <> 'churned'
GROUP BY 
	c.signup_date, 
	c.cust_status, 
	c.customer_segment, 
	u.logins_count
HAVING c.signup_date  IS NOT NULL
ORDER BY c.customer_segment ASC, days_before_churn DESC

-- Analyze the Revenue loss to churn per Month by Product

SELECT 
	DATEPART(MONTH, d.cleaned_transaction_date) transaction_month,
	DATENAME(MONTH, d.cleaned_transaction_date) transaction_month_name,
	ROUND(SUM(t.transaction_amount), 2) total_lost_revenue, 
	c.cust_status,
	p.cleaned_product cust_product
FROM [lb_salesDB].[fact].[transactions] t
LEFT JOIN [lb_salesDB].[dim].[customer] c
ON t.customer_key = c.customer_key
LEFT JOIN [lb_salesDB].[dim].[product] p
ON t.product_key = p.product_key
LEFT JOIN [lb_salesDB].[dim].[date] d
ON t.transac_date_key = d.transac_date_key
WHERE c.cust_status != 'active'
GROUP BY 
	DATEPART(MONTH, d.cleaned_transaction_date),
	DATENAME(MONTH, d.cleaned_transaction_date),
	p.cleaned_product, 
	c.cust_status
	
-- Analyze the percentage of Support Tickets as a Churn Predictor
WITH ticket_counts AS (
    SELECT
        u.support_tickets,
        c.cust_status,
        COUNT(*) AS customer_count
    FROM [lb_salesDB].[fact].[usage] u
    LEFT JOIN [lb_salesDB].[dim].[customer] c
        ON u.customer_key = c.customer_key
    WHERE u.support_tickets > 0
    GROUP BY 
        u.support_tickets,
        c.cust_status
),
total_per_status AS (
    SELECT
        cust_status,
        SUM(customer_count) AS total_customers
    FROM ticket_counts
    GROUP BY cust_status
)
SELECT
    t.support_tickets,
    t.cust_status,
    t.customer_count,
    ROUND(100.0 * t.customer_count / s.total_customers, 2) AS percentage_within_status
FROM ticket_counts t
JOIN total_per_status s
    ON t.cust_status = s.cust_status
ORDER BY 
    t.support_tickets,
    t.cust_status;

-- ==================================
-- CUSTOMER LIFETIME VALUE ANALYSIS
-- ==================================

-- What is the Average LTV by Country and Industry
WITH customer_base AS (
    SELECT
        c.customer_key,
        c.country,
        c.industry,
        c.cust_status,
        SUM(t.transaction_amount) AS total_revenue
    FROM [lb_salesDB].[dim].[customer] c
    LEFT JOIN [lb_salesDB].[fact].[transactions] t
        ON c.customer_key = t.customer_key
    GROUP BY 
        c.customer_key,
        c.country,
        c.industry,
        c.cust_status
),
arpu AS (
    SELECT
        country,
        industry,
        SUM(total_revenue) * 1.0 / COUNT(DISTINCT customer_key) AS arpu
    FROM customer_base
    WHERE cust_status = 'active'
    GROUP BY country, industry
),
churn AS (
    SELECT
        country,
        industry,
        COUNT(CASE WHEN cust_status = 'churned' THEN 1 END) * 1.0 /
        COUNT(DISTINCT customer_key) AS churn_rate
    FROM customer_base
    GROUP BY country, industry
)
SELECT
    a.country,
    a.industry,
    a.arpu,
    c.churn_rate,
    CASE 
        WHEN c.churn_rate = 0 THEN NULL
        ELSE a.arpu / c.churn_rate
    END AS avg_ltv
FROM arpu a
JOIN churn c
    ON a.country = c.country
    AND a.industry = c.industry
ORDER BY avg_ltv DESC;




SELECT 
	TOP (5) *
FROM [lb_salesDB].[dim].[date] p

SELECT TOP (5) *
FROM [lb_salesDB].[dim].[product] c


SELECT TOP (5) *
FROM [lb_salesDB].[fact].[usage] c