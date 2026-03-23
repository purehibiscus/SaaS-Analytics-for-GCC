WITH session_minutes AS (
	SELECT session_minutes,
		CASE session_minutes
			WHEN 'n/a' THEN NULL
			ELSE session_minutes
		END cleaned_session_minutes
	FROM (
		SELECT 
			session_minutes,
			CASE session_minutes
				WHEN 'n/a' THEN COALESCE(CAST(LTRIM(RTRIM(session_minutes)) AS FLOAT), 0)
				ELSE COALESCE(CAST(LTRIM(RTRIM(session_minutes)) AS FLOAT), 0)
			END AS fixing_data_type_inconsistency
		FROM [lb_salesDB].[dbo].[usage_me]
		)t
)

SELECT *
FROM session_minutes

--ALTER TABLE [lb_salesDB].[dbo].[usage_me]
--ADD cleaned_session_minutes FLOAT;

SELECT
	*
INTO #temp_session_minutes
FROM session_minutes

UPDATE [lb_salesDB].[dbo].[usage_me]
SET cleaned_session_minutes = #temp_session_minutes.cleaned_session_minutes
FROM #temp_session_minutes
WHERE [lb_salesDB].[dbo].[usage_me].session_minutes = #temp_session_minutes.session_minutes

-- features_used
SELECT 
	features_used,
	DATALENGTH(features_used) len_
	--ISNULL(features_used, '') AS isnull_value
FROM [lb_salesDB].[dbo].[usage_me]
GROUP BY features_used


WITH cleaned_usage_date AS (
	SELECT 
		usage_date,
		CAST(usage_date AS date) AS cleaned_usage_date
	FROM [lb_salesDB].[dbo].[usage_me]
)

SELECT *
INTO #temp_usage_date2
FROM cleaned_usage_date

ALTER TABLE [lb_salesDB].[dbo].[usage_me]
ADD cleaned_usage_date DATE;

UPDATE [lb_salesDB].[dbo].[usage_me]
SET cleaned_usage_date = #temp_usage_date2.cleaned_usage_date
FROM #temp_usage_date2
WHERE [lb_salesDB].[dbo].[usage_me].usage_date = #temp_usage_date2.usage_date


-- Finding days between each usage
SELECT 
	usage_date AS current_usage_date,
	LAG(usage_date) OVER (ORDER BY usage_date) AS previous_usage_date,
	DATEDIFF(DAY, LAG(usage_date) OVER (ORDER BY usage_date), usage_date) AS number_of_usage_days
FROM [lb_salesDB].[dbo].[usage_me]




SELECT *
FROM [lb_salesDB].[dbo].[usage_me]
