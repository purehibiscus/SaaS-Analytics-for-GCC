-- Churn flag column derivation
WITH churn_status AS (
	SELECT 
		*,
		CASE customer_active_status
			WHEN 'active' THEN 'Is active'
			WHEN 'churned' THEN 'Not active'
			ELSE customer_active_status
		END churn_status
	
	FROM [lb_salesDB].[dim].[customer]
	)

SELECT *
--INTO #temp_churn_status
FROM #temp_churn_status
FROM churn_status

ALTER TABLE [lb_salesDB].[dim].[customer]
ADD customer_active_status NVARCHAR(20);

UPDATE [lb_salesDB].[dim].[customer]
SET customer_active_status = #temp_churn_status.customer_active_status
FROM #temp_churn_status
WHERE #temp_churn_status.customer_id = [lb_salesDB].[dim].[customer].customer_id

SELECT TOP(10) *
FROM [lb_salesDB].[dim].[customer]

-- Tenure Derivation: This will help us ascertain the length of time every customer has been active since signup.

WITH customer_availability_status AS (
	SELECT 
		c.customer_id,
		d.signup_date,
		d.cleaned_transaction_date transaction_date,
		c.customer_active_status,
		CASE c.customer_active_status
			WHEN 'active' THEN 'customer_is_active'
			WHEN 'churned' THEN 'customer_left'
			ELSE customer_active_status
		END customer_availability_status
	FROM [lb_salesDB].[dim].[customer] c
	LEFT JOIN [lb_salesDB].[dim].[date] d
	ON c.signup_date = d.signup_date
	WHERE customer_active_status = 'customer_is_active'
)
SELECT *
FROM customer_availability_status



WITH tenure_in_years AS (	
	SELECT 
		*, 
		ROUND(COALESCE(final_time_since_signup_in_Months_by_12, 99999), 1) time_since_signup_in_years
	FROM (
		SELECT *,
			CAST(ABS(time_since_signup_in_Months) AS FLOAT) / 12 final_time_since_signup_in_Months_by_12
		FROM (
			SELECT 
				signup_date,
				cleaned_transaction_date last_transation_date,
				ABS(DATEDIFF(MONTH, signup_date, MAX(cleaned_transaction_date))) time_since_signup_in_Months,
				DATEDIFF(YEAR, signup_date, MAX(cleaned_transaction_date)) time_since_signup_in_12_months
			FROM [lb_salesDB].[dim].[date]
			GROUP BY cleaned_transaction_date, signup_date
		)t1
	)t2

)
SELECT * INTO #temp_tenure_in_years3
FROM tenure_in_years


ALTER TABLE [lb_salesDB].[dim].[date]
ADD time_since_signup_in_Months INT;

UPDATE [lb_salesDB].[dim].[date]
SET time_since_signup_in_Months = #temp_tenure_in_years3.time_since_signup_in_Months
FROM #temp_tenure_in_years3
WHERE #temp_tenure_in_years3.signup_date = [lb_salesDB].[dim].[date].signup_date

SELECT *

FROM #temp_tenure_in_years

SELECT *
FROM [lb_salesDB].[dim].[date]