-- ====================================================================
-- BELLABEAT DATA ANALYSIS CASE STUDY
-- Tool: Google Cloud BigQuery
-- Description: SQL queries covering data integrity,
--              cleaning, exploratory analysis, and user segmentation.
-- ====================================================================


-- ====================================================================
-- 1. DATA INTEGRITY CHECKS
-- ====================================================================

-- 1.1 Check how many unique users are in each table
SELECT 
    'daily_activity' AS table_name,
    COUNT(DISTINCT Id) AS unique_users,
    COUNT(*) AS total_rows
FROM `bellabeat-data-512722.bellabeat_data.daily_activity`

UNION ALL

SELECT 
    'sleep_day' AS table_name,
    COUNT(DISTINCT Id) AS unique_users,
    COUNT(*) AS total_rows
FROM `bellabeat-data-512722.bellabeat_data.sleep_day`

UNION ALL

SELECT 
    'hourly_steps' AS table_name,
    COUNT(DISTINCT Id) AS unique_users,
    COUNT(*) AS total_rows
FROM `bellabeat-data-512722.bellabeat_data.hourlySteps_merged`;


-- 1.2 Check for duplicate entries in the sleep table
SELECT 
    Id, 
    SleepDay, 
    COUNT(*) AS duplicate_count
FROM `bellabeat-data-512722.bellabeat_data.sleep_day`
GROUP BY Id, SleepDay
HAVING duplicate_count > 1;


-- ====================================================================
-- 2. DATA CLEANING & STANDARDIZATION
-- ====================================================================

-- 2.1 Clean sleep data: convert date string and calculate minutes awake in bed
SELECT
    Id,
    -- Convert text to a clean date
    DATE(PARSE_TIMESTAMP('%m/%d/%Y %I:%M:%S %p', SleepDay)) AS sleep_date,
    TotalSleepRecords,
    TotalMinutesAsleep,
    TotalTimeInBed,
    -- Time in bed minus time asleep = time tossing and turning
    (TotalTimeInBed - TotalMinutesAsleep) AS minutes_awake_in_bed
FROM 
    `bellabeat-data-512722.bellabeat_data.sleep_day`;


-- 2.2 Clean hourly steps: extract hour (0 to 23)
WITH formatted_hours AS (
  SELECT
    Id,
    PARSE_TIMESTAMP('%m/%d/%Y %I:%M:%S %p', ActivityHour) AS activity_time,
    StepTotal
  FROM 
    `bellabeat-data-512722.bellabeat_data.hourlySteps_merged`
)
SELECT
  Id,
  activity_time,
  EXTRACT(HOUR FROM activity_time) AS hour_of_day,
  StepTotal
FROM 
  formatted_hours;


-- ====================================================================
-- 3. EXPLORATORY DATA ANALYSIS (KEY HABITS & PATTERNS)
-- ====================================================================

-- 3.1 Overall daily averages (Steps, Active Minutes, Sedentary, Calories)
SELECT 
    ROUND(AVG(TotalSteps), 0) AS avg_daily_steps,
    ROUND(AVG(VeryActiveMinutes), 0) AS avg_very_active_mins,
    ROUND(AVG(FairlyActiveMinutes), 0) AS avg_fairly_active_mins,
    ROUND(AVG(LightlyActiveMinutes), 0) AS avg_lightly_active_mins,
    ROUND(AVG(SedentaryMinutes), 0) AS avg_sedentary_mins,
    ROUND(AVG(Calories), 0) AS avg_daily_calories
FROM 
    `bellabeat-data-512722.bellabeat_data.daily_activity`
WHERE 
    TotalSteps > 0; -- filter out days when device was not worn


-- 3.2 Sleep averages: Sleep hours vs. time awake in bed
SELECT 
    -- Average hours asleep
    ROUND(AVG(TotalMinutesAsleep) / 60, 1) AS avg_sleep_hours,
    -- Average hours spent in bed
    ROUND(AVG(TotalTimeInBed) / 60, 1) AS avg_time_in_bed_hours,
    -- Average minutes spent trying to fall asleep
    ROUND(AVG(TotalTimeInBed - TotalMinutesAsleep), 0) AS avg_minutes_awake_in_bed
FROM 
    `bellabeat-data-512722.bellabeat_data.sleep_day`;


-- 3.3 Peak activity hours throughout the day
WITH hourly_data AS (
  SELECT
    EXTRACT(HOUR FROM PARSE_TIMESTAMP('%m/%d/%Y %I:%M:%S %p', ActivityHour)) AS hour_of_day,
    StepTotal
  FROM 
    `bellabeat-data-512722.bellabeat_data.hourlySteps_merged`
)
SELECT 
    hour_of_day,
    ROUND(AVG(StepTotal), 0) AS avg_steps
FROM 
    hourly_data
GROUP BY 
    hour_of_day
ORDER BY 
    avg_steps DESC;


-- ====================================================================
-- 4. USER SEGMENTATION
-- ====================================================================

-- 4.1 Categorize users by activity level
SELECT 
    Id,
    ROUND(AVG(TotalSteps), 0) AS avg_daily_steps,
    CASE 
        WHEN AVG(TotalSteps) < 5000 THEN 'Sedentary'
        WHEN AVG(TotalSteps) BETWEEN 5000 AND 7499 THEN 'Lightly Active'
        WHEN AVG(TotalSteps) BETWEEN 7500 AND 9999 THEN 'Fairly Active'
        ELSE 'Very Active'
    END AS activity_category
FROM 
    `bellabeat-data-512722.bellabeat_data.daily_activity`
WHERE 
    TotalSteps > 0
GROUP BY 
    Id
ORDER BY 
    avg_daily_steps DESC;


-- 4.2 Group users by how consistently they wore their tracker
SELECT 
    Id,
    COUNT(ActivityDate) AS total_logged_days,
    CASE 
        WHEN COUNT(ActivityDate) >= 25 THEN 'High Usage (25-31 days)'
        WHEN COUNT(ActivityDate) BETWEEN 15 AND 24 THEN 'Moderate Usage (15-24 days)'
        ELSE 'Low Usage (< 15 days)'
    END AS device_usage_segment
FROM 
    `bellabeat-data-512722.bellabeat_data.daily_activity`
GROUP BY 
    Id
ORDER BY 
    total_logged_days DESC;
