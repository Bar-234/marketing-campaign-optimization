-- Basic data exploration

SELECT COUNT(*) AS total_records FROM marketing_campaign;
SELECT COUNT (DISTINCT user_id ) AS unique_users FROM marketing_campaign

-- Check for missing value
SELECT
  COUNT(*) - COUNT(user_id) AS missing_user_id,
  COUNT(*) - COUNT(test_group) AS missing_test_group,
  COUNT(*) - COUNT(converted) AS missing_converted,
  COUNT(*) - COUNT(total_ads) AS missing_total_ads
FROM marketing_campaign;

-- Check for duplicates
SELECT user_id, COUNT(*)
FROM marketing_campaign
GROUP BY user_id
HAVING COUNT(*) > 1;

-- Remove duplicates if any
DELETE FROM marketing_campaign
WHERE idx NOT IN (
	SELECT MIN(idx)
	FROM marketing_campaign
	GROUP BY user_id
);

-- Data Overview
SELECT
  MIN(total_ads) AS min_ads,
  MAX(total_ads) AS max_ads,
  AVG(total_ads) AS avg_ads,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_ads) AS median_ads
  FROM marketing_campaign;

--MARKETING KPIs CALCULATION 

-- Overall Conversion Rate
SELECT
     COUNT(*) AS total_users,
     SUM(CASE WHEN converted= TRUE THEN 1 ELSE 0 END) AS conversions,
     ROUND(100.0 * SUM (CASE WHEN converted=TRUE THEN 1 ELSE 0 END)/ COUNT(*),2) AS conversion_rate_pct
FROM marketing_campaign ;

-- A/B Test Performance Comparison
SELECT
   CASE WHEN test_group = 'ad' THEN 'Test Group' ELSE 'Control Group' END as group_name,
   COUNT(*) AS users,
   SUM(CASE WHEN converted = TRUE THEN 1 ELSE 0 END) AS conversions,
   ROUND(100 * SUM(CASE WHEN converted = TRUE THEN 1 ELSE 0 END)/ COUNT(*),2) AS conversion_rate_pct
FROM marketing_campaign
GROUP BY test_group;

-- Conversion by Ad Frequency
SELECT
    CASE
       WHEN total_ads < 10 THEN 'Low(0-9 ads)'
       WHEN total_ads BETWEEN 10 AND 20 THEN 'Medium(10-20 ads)'
       ELSE 'High(20+ads)'
     END AS ad_frequency_bucket,
     COUNT(*) as users,
     SUM(CASE WHEN converted= TRUE THEN 1 ELSE 0 END) as conversions,
     ROUND(100 * SUM(CASE WHEN converted = TRUE THEN 1 ELSE 0 END) / COUNT(*), 2 ) AS
	 conversion_rate_pct
FROM marketing_campaign
GROUP BY ad_frequency_bucket
ORDER BY ad_frequency_bucket;

-- Performance by hour
SELECT
  most_ads_hour,
  COUNT(*) AS users,
  SUM(CASE WHEN converted= TRUE THEN 1 ELSE 0 END) AS conversions,
  ROUND(100 * SUM(CASE WHEN converted= TRUE THEN 1 ELSE 0 END) / COUNT(*), 2) AS conversion_rate_pct
FROM marketing_campaign
GROUP BY most_ads_hour
ORDER BY conversion_rate_pct DESC;

-- Performance by Day
SELECT
 most_ads_day,
  COUNT(*) AS users,
  SUM(CASE WHEN converted= TRUE THEN 1 ELSE 0 END) AS conversions,
  ROUND(100 * SUM(CASE WHEN converted= TRUE THEN 1 ELSE 0 END)/COUNT(*),2) AS conversion_rate_pct
FROM marketing_campaign
GROUP BY most_ads_day
ORDER BY conversion_rate_pct DESC;

-- Average ads for converters vs non-converters
SELECT
   CASE WHEN converted= TRUE THEN 'Converted' ELSE 'NOT Converted' END AS status,
   ROUND(AVG(total_ads),2) AS avg_ads_shown,
   MIN(total_ads) AS min_ads,
   MAX(total_ads) AS max_ads
FROM marketing_campaign
GROUP BY converted;

-- RFM ANALYSIS

-- Create RFM scores (adapted for ad campaign data)
WITH rfm_calc AS (
	SELECT
	  user_id,
	  total_ads AS frequency_score, --F: Number of ads shown
	  CASE WHEN converted = TRUE THEN 100 ELSE 0 END AS monetary_score, --M: Conversion value
	  CASE 
	     WHEN most_ads_day IN ('Monday', 'Tuesday') THEN 5 --Recent engagement
	     WHEN most_ads_day IN ('Wednesday','Thursday') THEN 3
	     ELSE 1
	END AS recency_score, --R : Recency proxy
	converted,
	test_group
FROM marketing_campaign	
) ,

rfm_segments AS (
	SELECT 
	  user_id,
	  frequency_score,
	  monetary_score,
	  recency_score,
	  converted,
	  test_group,
	--Create RFM segments
	CASE
	  WHEN monetary_score = 100 AND frequency_score<15 THEN 'Champions'
	  WHEN monetary_score =100 AND frequency_score >= 15 THEN 'Loyal Customers'
	  WHEN monetary_score = 0 AND frequency_score>=20 THEN 'At Risk'
	  WHEN monetary_score = 0 AND frequency_score <10 THEN 'Lost'
	  ELSE 'Potential'
	END AS customer_segment
FROM rfm_calc	
)

SELECT
   customer_segment,
   COUNT(*) AS segment_size,
   ROUND(100 * COUNT(*)/ SUM(COUNT(*))OVER() ,2) AS segment_percentage,
   ROUND(AVG(frequency_score),2) AS avg_ads,
   SUM(CASE WHEN converted= TRUE THEN 1 ELSE 0 END) AS conversions
FROM rfm_segments
GROUP BY customer_segment
ORDER BY conversions DESC;
	
-- Exported cleaned data for python
\copy (
SELECT 
	  user_id,
	  CASE WHEN test_group ='ad'  THEN 1 ELSE 0 END AS test_group,
	  CASE WHEN converted = TRUE THEN 1 ELSE 0 END AS converted,
	  total_ads,
	  most_ads_hour,
	  most_ads_day
	FROM marketing_campaign;
) TO 'C:/Users/Sony/Desktop/marketing_clean.csv'
CSV HEADER;









