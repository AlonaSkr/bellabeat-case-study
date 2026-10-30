-- ====================================================================
-- BELLABEAT: TABLEAU-READY EXPORTS
-- ====================================================================


-- --------------------------------------------------------------------
-- Export 1: activity_time_allocation.csv
-- Average minutes per day at each activity level (one row per level).
-- Used for: "Where does the day go?" bar chart
-- --------------------------------------------------------------------
SELECT
    activity_level,
    ROUND(AVG(minutes), 0) AS avg_minutes
FROM `bellabeat-data-512722.bellabeat_data.daily_activity`
UNPIVOT (
    minutes FOR activity_level IN (
        SedentaryMinutes     AS 'Sedentary',
        LightlyActiveMinutes AS 'Lightly Active',
        FairlyActiveMinutes  AS 'Fairly Active',
        VeryActiveMinutes    AS 'Very Active'
    )
)
WHERE TotalSteps > 0   -- exclude days the tracker was not worn
GROUP BY activity_level;


-- --------------------------------------------------------------------
-- Export 2: sleep_nightly.csv
-- One row per user per night (duplicates already removed).
-- Used for: sleep scatter plot and sleep KPIs
-- --------------------------------------------------------------------
SELECT
    Id,
    sleep_date,
    TotalMinutesAsleep,
    TotalTimeInBed,
    minutes_awake_in_bed
FROM `bellabeat-data-512722.bellabeat_data.sleep_day_clean`;


-- --------------------------------------------------------------------
-- Export 3: hourly_avg_steps.csv
-- Average steps for each hour of the day (24 rows).
-- Used for: intraday activity line chart
-- --------------------------------------------------------------------
SELECT
    hour_of_day,
    ROUND(AVG(StepTotal), 0) AS avg_steps
FROM `bellabeat-data-512722.bellabeat_data.hourly_steps_clean`
GROUP BY hour_of_day
ORDER BY hour_of_day;


-- --------------------------------------------------------------------
-- Export 4: user_segments.csv
-- One row per user with both segments (activity level + device usage).
-- Used for: segmentation bar charts
-- Note: average steps ignore zero-step days (same as query 4.1);
--       logged days count every record (same as query 4.2).
-- --------------------------------------------------------------------
SELECT
    Id,
    ROUND(AVG(IF(TotalSteps > 0, TotalSteps, NULL)), 0) AS avg_daily_steps,
    CASE
        WHEN AVG(IF(TotalSteps > 0, TotalSteps, NULL)) < 5000  THEN 'Sedentary'
        WHEN AVG(IF(TotalSteps > 0, TotalSteps, NULL)) < 7500  THEN 'Lightly Active'
        WHEN AVG(IF(TotalSteps > 0, TotalSteps, NULL)) < 10000 THEN 'Fairly Active'
        ELSE 'Very Active'
    END AS activity_category,
    COUNT(ActivityDate) AS total_logged_days,
    CASE
        WHEN COUNT(ActivityDate) >= 25 THEN 'High Usage (25-31 days)'
        WHEN COUNT(ActivityDate) >= 15 THEN 'Moderate Usage (15-24 days)'
        ELSE 'Low Usage (< 15 days)'
    END AS device_usage_segment
FROM `bellabeat-data-512722.bellabeat_data.daily_activity`
GROUP BY Id;


-- --------------------------------------------------------------------
-- Export 5: daily_steps_calories.csv
-- One row per user per worn day.
-- Used for: steps vs. calories scatter plot (optional)
-- --------------------------------------------------------------------
SELECT
    Id,
    ActivityDate,
    TotalSteps,
    Calories,
    SedentaryMinutes
FROM `bellabeat-data-512722.bellabeat_data.daily_activity`
WHERE TotalSteps > 0;
