SELECT 
      *
  FROM [lb_salesDB].[dbo].[customers_me]
-- =================
-- DATA CLEANING --
-- =================
-- Here, I will address all data inconsistencies, data quality issues, NULL values, trailing and leading spaces.
-- The country name field data is having inconsistent letter case, misspelt country names, and leading and trailing spaces.
-- The leading and trailing spaces cannot be seen with 

-- 1. Addressing case inconsistencies, misspelt country names, and removing non-printing characters in customer country

ALTER TABLE [lb_salesDB].[dbo].[customers_me]
ADD cleaned_country_name NVARCHAR(50);

UPDATE c
SET cleaned_country_name =
    CASE
        WHEN t.trimmed_country IN ('0qatar', 'qatar', 'aatar') 
            THEN 'QATAR'

        WHEN t.trimmed_country IN ('bahren', 'bharain', 'bahrain') 
            THEN 'BAHRAIN'

        WHEN t.trimmed_country IN ('kuwet', 'kuwait') 
            THEN 'KUWAIT'

        WHEN t.trimmed_country IN ('oman', 'omann') 
            THEN 'OMAN'

        WHEN t.trimmed_country IN (
            'dubai', 'u?a', 'uea', 'ua?', 'uaedubai',
            'uaee', 'uaea', 'uae', 'u.a.e', 'uae.'
        ) 
            THEN 'UAE'

        WHEN t.trimmed_country IN (
            'saudiarabia', 'saudi-arabia',
            'ssudiarabiya', 'sudiarabia'
        ) 
            THEN 'SAUDI ARABIA'

        ELSE UPPER(LTRIM(RTRIM(c.country)))
    END
FROM [lb_salesDB].[dbo].[customers_me] c
CROSS APPLY (
    SELECT 
        LOWER(
            REPLACE(
                REPLACE(
                    REPLACE(LTRIM(RTRIM(c.country)), ' ', ''),
                '.', ''),
            '-', '')
        ) AS trimmed_country
) t;

-- 2. Fixing data issues in industry names with CTE and inserting the result in a temp table
SELECT 
	industry,
	COUNT(*) AS length_with_spaces,
	LEN(industry) AS length_
FROM [lb_salesDB].[dbo].[customers_me]
GROUP BY industry


WITH cleaned_industry AS (
	SELECT 
		industry,
			REPLACE(
				REPLACE(
					LTRIM(
						RTRIM(industry)), ' ', ''), 'Telecomm', 'Telecom') AS cleaned_industry
	FROM [lb_salesDB].[dbo].[customers_me]
	
)

-- SELECT *
-- FROM cleaned_industry;

SELECT * 
INTO #temp_industry2 
FROM cleaned_industry;

SELECT * FROM #temp_industry2

ALTER TABLE [lb_salesDB].[dbo].[customers_me]
ADD cleaned_industry NVARCHAR(50);

UPDATE [lb_salesDB].[dbo].[customers_me]
SET cleaned_industry = #temp_industry2.cleaned_industry
FROM #temp_industry2
WHERE [lb_salesDB].[dbo].[customers_me].industry = #temp_industry2.industry;

SELECT *
FROM [lb_salesDB].[dbo].[customers_me]

--3. Addressing customer_segment values, here, the NULLs are taking spaces that could affect scalability
SELECT
	customer_segment,
	COUNT(*) AS customer_segment_with_spaces_length,
	LEN(customer_segment) _trimmed_customer_segment_length
FROM [lb_salesDB].[dbo].[customers_me]
GROUP BY customer_segment

WITH cleaned_cust_segment AS (
	SELECT
		customer_segment,
		LTRIM(RTRIM(customer_segment)) cleaned_customer_segment
	FROM [lb_salesDB].[dbo].[customers_me] 
) 

--SELECT *
--FROM cleaned_cust_segment

--SELECT *
--INTO #temp_customer_segment2

ALTER TABLE [lb_salesDB].[dbo].[customers_me]
ADD cleaned_customer_segment NVARCHAR(50);

UPDATE [lb_salesDB].[dbo].[customers_me]
SET cleaned_customer_segment = #temp_customer_segment2.cleaned_customer_segment
FROM #temp_customer_segment2
WHERE [lb_salesDB].[dbo].[customers_me].customer_segment = #temp_customer_segment2.customer_segment; 

-- 4. 


WITH cleaned_customer_acquisition_channels AS ( 
	SELECT
		*
	FROM (
		SELECT 
			*,
			REPLACE(
				REPLACE(
					LTRIM(
						RTRIM(acquisition_channel)), 'Paid    Ads', 'Paid-Ads'), ' ', '-') AS trimmed_acquisition_channels,
			LOWER(
				REPLACE(
					LTRIM(
						RTRIM(status)), '\', '')) AS cleaned_status
		FROM [lb_salesDB].[dbo].[customers_me]
	) AS cleaned_customer_me_data
) 

SELECT * FROM cleaned_customer_acquisition_channels;

SELECT TOP (10) *
FROM [lb_salesDB].[dbo].[customers_me]

ALTER TABLE [lb_salesDB].[dbo].[customers_me]
ADD trimmed_acquisition_channels NVARCHAR(50),
	cleaned_status NVARCHAR(20);

UPDATE [lb_salesDB].[dbo].[customers_me]
SET cleaned_status = #temp_customer_acquisition.cleaned_status
FROM #temp_customer_acquisition
WHERE [lb_salesDB].[dbo].[customers_me].customer_segment = #temp_customer_acquisition.customer_segment; 
