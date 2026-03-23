SELECT TOP (1000) [transaction_id]
      ,[customer_id]
      ,[transaction_date]
      ,[product_category]
      ,[payment_method]
      ,[amount_usd]
      ,[currency]
      ,[discount_applied]
  FROM [lb_salesDB].[dbo].[transactions_me]

SELECT 
	payment_method,
	COUNT(*) AS length_with_spaces,
	LEN(payment_method) AS len_no_space
 FROM [lb_salesDB].[dbo].[transactions_me]
 GROUP BY payment_method

ALTER TABLE [lb_salesDB].[dbo].[transactions_me]
ADD cleaned_payment_method NVARCHAR(50);

UPDATE p
SET cleaned_payment_method =
    CASE
        WHEN t.trimmed_payment_method IN ('cash', 'Cash') 
            THEN 'CASH'

		WHEN t.trimmed_payment_method IN ('card', 'Card') 
            THEN 'CARD'
		
		WHEN t.trimmed_payment_method IN ('bank transfer', 'Bank Transfer') 
            THEN 'BANK TRANSFER'

        ELSE UPPER(LTRIM(RTRIM(p.payment_method)))
    END
FROM [lb_salesDB].[dbo].[transactions_me] p
CROSS APPLY (
    SELECT 
        UPPER(
			REPLACE(
				LTRIM(
					RTRIM(p.payment_method)), ' ', '')
        ) AS trimmed_payment_method
) t;



SELECT *
FROM [lb_salesDB].[dbo].[transactions_me]

SELECT Distinct product_category
FROM [lb_salesDB].[dbo].[transactions_me]



WITH cleaned_product AS (
	SELECT 
		product_category,
		REPLACE(
			REPLACE(
				LTRIM(
					RTRIM(product_category)), ' ', ''), 'Addon', 'Add-on') AS cleaned_product
	FROM [lb_salesDB].[dbo].[transactions_me]
)

SELECT * 
INTO #temp_product
FROM cleaned_product

ALTER TABLE  [lb_salesDB].[dbo].[transactions_me]
ADD cleaned_product NVARCHAR(50);

UPDATE [lb_salesDB].[dbo].[transactions_me]
SET cleaned_product = #temp_product.cleaned_product
FROM #temp_product
WHERE [lb_salesDB].[dbo].[transactions_me].product_category = #temp_product.product_category;


-- amount_usd FX conversion (2026-02-06)
	

WITH fixed_fx_rate AS (	
	SELECT
		currency,
		CASE currency
			WHEN 'AED' THEN ROUND(COALESCE(CAST(amount_usd AS FLOAT), 0), 2) * 0.2723
			WHEN 'SAR' THEN ROUND(COALESCE(CAST(amount_usd AS FLOAT), 0), 2) * 0.2667
			ELSE ROUND(COALESCE(CAST(amount_usd AS FLOAT), 0), 2)
		END  AS fixed_FX_rates
	FROM [lb_salesDB].[dbo].[transactions_me]
	)
--SELECT *
--FROM fixed_fx_rate

SELECT * INTO #temp_fx_rates FROM fixed_fx_rate

SELECT *
FROM #temp_fx_rates

ALTER TABLE  [lb_salesDB].[dbo].[transactions_me]
ADD fixed_FX_rates FLOAT;

UPDATE [lb_salesDB].[dbo].[transactions_me]
SET fixed_FX_rates = #temp_fx_rates.fixed_FX_rates
FROM #temp_fx_rates
WHERE [lb_salesDB].[dbo].[transactions_me].currency = #temp_fx_rates.currency;


-- Handling NULLS and Zero in discount_applied to data scalability and optimization

WITH discount_flag AS (
	SELECT
		discount_applied, currency

WITH discount_status AS (
	SELECT discount_applied,
		CASE 
			WHEN discount_applied = '0' THEN NULL
			ELSE discount_applied
		END AS status_
	FROM [lb_salesDB].[dbo].[transactions_me]
	
)
, discount_application_status 
(
	SELECT 
		discount_applied,
			CASE 
				WHEN status_ IS NOT NULL THEN 'Discount_applied'
				ELSE 'No_discount'
			END discount_applied_status
		FROM [lb_salesDB].[dbo].[transactions_me]
)

SELECT 
FROM discount_application_status

SELECT TOP (10)


WITH cleaned_transaction_date AS (
	SELECT 
		transaction_date,
		CAST(transaction_date AS date) AS cleaned_transaction_date
	FROM [lb_salesDB].[dbo].[transactions_me]
)

SELECT *
INTO #temp_transaction_date
FROM cleaned_transaction_date

ALTER TABLE [lb_salesDB].[dbo].[transactions_me]
ADD cleaned_transaction_date DATE;

UPDATE [lb_salesDB].[dbo].[transactions_me]
SET cleaned_transaction_date = #temp_transaction_date.cleaned_transaction_date
FROM #temp_transaction_date
WHERE [lb_salesDB].[dbo].[transactions_me].transaction_date = #temp_transaction_date.transaction_date

SELECT TOP (10) *
FROM [lb_salesDB].[dbo].[transactions_me]
