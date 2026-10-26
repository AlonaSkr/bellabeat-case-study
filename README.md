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

During the data ingestion process in Google BigQuery, date and timestamp attributes required explicit parsing and metric engineering:

1. **Standardizing Dates & Calculating Sleep Latency:**
   The `SleepDay` column contained combined date-time strings with 12-hour AM/PM formatting. Dates were parsed to standard `DATE` objects, and a derived field `minutes_awake_in_bed` was created to evaluate sleep latency:
   ```sql
   SELECT
       Id,
       PARSE_DATE('%m/%e/%Y', SPLIT(SleepDay, ' ')[OFFSET(0)]) AS sleep_date,
       TotalSleepRecords,
       TotalMinutesAsleep,
       TotalTimeInBed,
       (TotalTimeInBed - TotalMinutesAsleep) AS minutes_awake_in_bed
   FROM `bellabeat_data.sleep_day`;

   SELECT
       Id,
       EXTRACT(HOUR FROM PARSE_TIMESTAMP('%m/%d/%Y %I:%M:%S %p', ActivityHour)) AS hour_of_day,
       StepTotal
   FROM `bellabeat_data.hourly_steps`;

