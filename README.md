# 🌿 Bellabeat Data Analysis Case Study
**Google Data Analytics Professional Certificate Capstone**

---

## 📌 Project Overview
This project is a portfolio case study completed as part of the **Google Data Analytics Professional Certificate**. In this scenario, I act as a junior data analyst on the marketing analytics team at **Bellabeat**, a high-tech manufacturer of health-focused wellness smart devices designed specifically for women.

Urška Sršen, Cofounder and Chief Creative Officer of Bellabeat, believes that analyzing consumer smart device fitness data can unlock new growth opportunities for the company. This analysis focuses on non-Bellabeat smart device data (Fitbit) to uncover consumer usage habits and translate those patterns into actionable marketing recommendations for Bellabeat's executive team.

---

## 🎯 Business Task
Analyze public consumer smart-device fitness data (specifically tracking daily activity, intensity, sedentary behavior, and sleep patterns) to uncover usage habits and behavioral trends, map those insights onto Bellabeat’s product ecosystem (primarily the **Leaf** tracker and **Bellabeat App**), and deliver actionable, data-driven marketing recommendations that optimize user engagement, customer acquisition, and brand positioning in the global women’s wellness market.

---

## 👥 Key Stakeholders
* **Urška Sršen:** Bellabeat Cofounder and Chief Creative Officer
* **Sando Mur:** Mathematician and Bellabeat Cofounder (Executive Team Member)
* **Bellabeat Marketing Analytics Team:** Core analytics team guiding data-driven marketing campaigns

---

## 🧭 Analysis Framework
The project strictly adheres to the six stages of the Google Data Analysis process:

1. **Ask:** Define business questions, identify key objectives, and align with stakeholder goals.
2. **Prepare:** Collect and store data, evaluate credibility and bias using the ROCCC framework.
3. **Process:** Clean, transform, validate, and document data preparation to ensure integrity.
4. **Analyze:** Aggregate, organize, and perform exploratory data analysis (EDA) to uncover trends.
5. **Share:** Design executive-level data visualizations and communicate findings effectively.
6. **Act:** Deliver actionable, high-level marketing strategies and product recommendations.

---

## 🛠️ Tools & Technologies
* **Data Storage & Cleaning:** Google BigQuery (SQL)
* **Data Visualization:** Tableau Public
* **Documentation & Version Control:** Markdown, Git, GitHub

---

## 📂 Data Sources & Architecture
The primary dataset used for this case study is the **FitBit Fitness Tracker Data** (publicly available via [Kaggle](https://www.kaggle.com/datasets/arashnic/fitbit) and stored under a public domain dedication).

* **Source Entity:** Collected by Mobius via Amazon Mechanical Turk.
* **Original Study Citation:** Furberg, R., Brinton, J., Keating, M., & Ortiz, A. (2016). *Crowdsourced Fitbit datasets 03.12.2016-05.12.2016* [Data set]. Zenodo.
* **Collection Window:** April 12, 2016 – May 12, 2016 (31-day monitoring window).
* **Sample Size:** 33 unique eligible Fitbit users who consented to the submission of personal tracker data.

### Core Datasets Selected for Analysis
While the raw repository contains 18 separate CSV files at varying granularities (seconds, minutes, hours, days), the following three relational tables were selected to answer Bellabeat's executive business questions:

| Table Name | Primary Keys | Key Attributes & Metrics | Business Relevance |
| :--- | :--- | :--- | :--- |
| **`daily_activity`**<br>*(dailyActivity_merged.csv)* | `Id`, `ActivityDate` | `TotalSteps`, `TotalDistance`, `VeryActiveMinutes`, `FairlyActiveMinutes`, `LightlyActiveMinutes`, `SedentaryMinutes`, `Calories` | Evaluates overall daily movement, energy expenditure, intensity breakdown, and baseline activity habits. |
| **`sleep_day`**<br>*(sleepDay_merged.csv)* | `Id`, `SleepDay` | `TotalSleepRecords`, `TotalMinutesAsleep`, `TotalTimeInBed` | Analyzes rest patterns, sleep duration adequacy, and sleep onset latency (time awake in bed). |
| **`hourly_steps`**<br>*(hourlySteps_merged.csv)* | `Id`, `ActivityHour` | `StepTotal` | Uncovers intraday temporal patterns to identify peak movement intervals and sluggish periods throughout the day. |

---

## ⚠️ Data Limitations & Bias Analysis (ROCCC)
* **Reliable (Low):** Small sample size ($N = 33$ unique users in daily activity; $N = 24$ in sleep logs).
* **Original (Low):** Crowdsourced via Amazon Mechanical Turk rather than direct first-party telemetry.
* **Comprehensive (Low):** No demographic information (gender, age, location). Since Bellabeat builds for women, insights must be evaluated as general human activity habits rather than female-specific physiology.
* **Current (Low):** Collected in Spring 2016. Consumer wearable hardware and habits have evolved.
* **Cited (Medium):** Well-documented methodology via Zenodo under CC0: Public Domain.


## ⚙️ Data Cleaning & Transformation (Process Phase)

The raw Fitbit datasets were audited and cleaned in **Google Cloud BigQuery** to resolve formatting errors, remove non-wear artifacts, and engineer derived metrics for analysis.

---

### 🛠️ Step-by-Step Data Cleaning Breakdown

#### 1. Cleaning Sleep Records & Calculating Sleep Latency (`sleep_day`)
The raw `SleepDay` column contained 12-hour AM/PM text strings. This query standardizes the date into `YYYY-MM-DD` and creates a derived metric (`minutes_awake_in_bed`) to measure how long users toss and turn before falling asleep.

```sql
SELECT
    Id,
    -- Convert text to standard calendar date (YYYY-MM-DD)
    DATE(PARSE_TIMESTAMP('%m/%d/%Y %I:%M:%S %p', SleepDay)) AS sleep_date,
    TotalSleepRecords,
    TotalMinutesAsleep,
    TotalTimeInBed,
    -- Feature Engineering: Time in bed minus time asleep = sleep latency
    (TotalTimeInBed - TotalMinutesAsleep) AS minutes_awake_in_bed
FROM `bellabeat_data.sleep_day`;
``` 
Parsing Intraday Intervals (hourly_steps)
Raw timestamps were converted to timestamps to extract the integer hour (0 to 23). This enables grouping movement patterns across a 24-hour day to pinpoint peak activity hours.

```
WITH clean_steps AS (
    SELECT
        Id,
        -- Step 1: Parse string into a valid timestamp
        PARSE_TIMESTAMP('%m/%d/%Y %I:%M:%S %p', ActivityHour) AS activity_time,
        StepTotal
    FROM `bellabeat_data.hourly_steps`
)
SELECT
    Id,
    activity_time,
    -- Step 2: Extract hour integer (0 to 23)
    EXTRACT(HOUR FROM activity_time) AS hour_of_day,
    StepTotal
FROM clean_steps;
Filtering Unworn Tracker Days (daily_activity)
```
Smart tracker datasets often contain days where the tracker was uncharged or left on a nightstand.

-- Filter out zero-step days during aggregation
```
SELECT *
FROM `bellabeat_data.daily_activity`
WHERE TotalSteps > 0;
```

Why this matters: Records with TotalSteps = 0 or 1,440 sedentary minutes (an entire 24-hour cycle) represent non-wear time rather than true human behavior. Filtering them out prevents artificial deflation of daily activity and calorie averages.

Checking and Resolving Duplicate Records
Composite keys (Id + SleepDay) were checked to ensure unique daily entries.

-- Check for duplicate daily logs
```
SELECT 
    Id, 
    SleepDay, 
    COUNT(*) AS duplicate_count
FROM `bellabeat_data.sleep_day`
GROUP BY Id, SleepDay
HAVING duplicate_count > 1;
```

Finding: Identified 3 duplicate rows in sleep_day where the same user logged identical stats for the same date. These were isolated to prevent double-counting sleep hours.

-----------------------

## 📊 Exploratory Data Analysis & Key Insights (Analyze Phase)

Using Google BigQuery, exploratory queries were conducted across the cleaned datasets to identify consumer habits, sleep behaviors, and temporal activity trends.

---

### 1. Daily Activity Baseline: The Sedentary Reality
* **Average Daily Steps:** ~7,638 steps per day, falling short of the widely recommended 10,000 steps per day benchmark.
* **Time Allocation Breakdown:**
  * **Sedentary Time:** ~991 minutes (~16.5 hours/day), representing the vast majority of waking and resting hours.
  * **Lightly Active Time:** ~193 minutes (~3.2 hours/day).
  * **Fairly Active Time:** ~14 minutes/day.
  * **Very Active Time:** ~21 minutes/day.
* **Key Finding:** Consumers are predominantly sedentary desk workers or casual movers rather than fitness enthusiasts. Intense workouts represent only ~1.5% of their daily time.

---

### 2. Sleep Efficiency & Rest Patterns
* **Average Sleep Duration:** ~419 minutes (~7.0 hours per night), which meets standard health recommendations (7–9 hours).
* **Average Time in Bed:** ~458 minutes (~7.6 hours per night).
* **Sleep Latency (Time Awake in Bed):** Users spend an average of **~39 minutes** awake in bed tossing and turning before falling asleep or after waking up.
* **Adherence Gap:** While 33 users logged daily movement, only 24 users tracked sleep, revealing significant user friction with wearing wristbands overnight.

---

### 3. Intraday Movement Patterns (Hourly Distribution)
Analyzing hourly step distributions revealed distinct daily behavioral cycles:
* **Morning Inactivity:** Low movement until 8:00 AM.
* **Lunchtime Surge (12:00 PM – 2:00 PM):** A notable spike in steps as users break for lunch and run errands.
* **Afternoon Slump (2:00 PM – 4:00 PM):** Activity sharply drops as users return to sedentary work.
* **Peak Evening Window (5:00 PM – 7:00 PM):** Highest activity volume of the entire day, corresponding with evening commutes, gym sessions, and outdoor walks.

---

### 4. User Segmentation

#### A. Activity Level Breakdown (Based on Daily Step Volume)
Users were classified into four standardized activity categories:
1. **Sedentary (< 5,000 steps/day):** ~24% of users.
2. **Lightly Active (5,000 – 7,499 steps/day):** ~27% of users.
3. **Fairly Active (7,500 – 9,999 steps/day):** ~27% of users.
4. **Very Active (10,000+ steps/day):** ~21% of users.

#### B. Device Tracking Adherence (Consistency Over 31 Days)
* **High Usage (25–31 active days):** ~80% of users wore and logged activity consistently throughout the month.
* **Moderate Usage (15–24 active days):** ~12% of users.
* **Low Usage (< 15 active days):** ~8% of users exhibited tracking drop-off, likely due to charging friction or lost habit.

---

## 💡 Strategic Marketing Recommendations (Act Phase)

Based on these behavioral insights, Bellabeat has a prime opportunity to position its products (particularly the **Bellabeat Leaf** and **Bellabeat App**) to solve these specific user friction points.

### 1. Position the Bellabeat Leaf as the "Effortless 24/7 Sleep Companion"
* **The Problem:** 27% of users failed to track sleep, and wrist-worn fitness trackers are notoriously uncomfortable to sleep with.
* **The Strategy:** Highlight that the **Leaf** can be clipped to sleepwear, worn as a lightweight pendant, or attached as a discreet accessory. Market its **up to 6-month battery life** (no nightly charging cables) to capture consumers who quit traditional fitness watches due to charging friction.

### 2. Introduce In-App "Mindful Wind-Down" Tools for Sleep Latency
* **The Problem:** Users spend an average of ~39 minutes awake in bed attempting to sleep.
* **The Strategy:** The Bellabeat App should trigger gentle "wind-down" notifications 45 minutes before target sleep schedules. Promote guided bedtime meditations, breathwork, and ambient soundscapes within the Bellabeat membership to improve sleep onset efficiency.

### 3. Combat the Afternoon Slump with Smart Prompts
* **The Problem:** Prolonged sedentary periods occur between 2:00 PM and 4:00 PM.
* **The Strategy:** Use subtle, customizable vibration reminders on the Bellabeat tracker during mid-afternoon hours to prompt brief 5-minute movement or hydration breaks. Frame these not as intense fitness demands, but as stress-reduction and focus-boosting rituals.

### 4. Tiered Habit Coaching Instead of the 10,000-Step Hurdle
* **The Problem:** Over 50% of consumers take fewer than 7,500 steps per day. Imposing rigid 10,000-step goals can lead to frustration and device abandonment.
* **The Strategy:** In marketing campaigns and onboarding flows, emphasize holistic wellness and achievable micro-goals (e.g., "Add 1,000 steps to your natural daily rhythm") rather than aggressive athletic metrics.

