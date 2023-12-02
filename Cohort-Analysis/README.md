# Cohort Analysis with SQL and Metabase

## Overview
Cohort analysis is a powerful method for understanding user behavior over time. This repository contains SQL code and Metabase visualizations to perform cohort analysis, helping you gain insights into user retention and engagement.

## Cohort Analysis
Cohort analysis involves grouping users based on a common characteristic, such as the week they joined, and tracking their behavior over time. This analysis can unveil patterns in user retention and highlight the impact of specific events or changes.

## Raw Data
To use this cohort analysis framework, you need a dataset with the following structure:

| ds (date format) | user_id |
|-------------------|---------|
| yyyy-mm-dd        | xxxxxxx |

This table should contain the user's registration date (`ds`) and a unique identifier for each user (`user_id`).

## Code
### SQL Queries
The SQL code in this repository is structured using Common Table Expressions (CTEs) to extract and analyze relevant data. It calculates cohort sizes, tracks user activity, and computes key metrics such as age index and retention rate.

#### Common Table Expressions (CTEs)
- `week`: Retrieves the week of the year for each date.
- `data`: Extracts relevant data for conversions.
- `events`: Joins data with the latest week information.
- `user_cohort`: Creates user cohorts with the earliest week of activity.
- `cohort_size`: Calculates cohort sizes.
- `cohort_activity`: Calculates cohort activity (active users per week).

#### Final Query
The final query calculates age, age index, and retention rate, providing a comprehensive view of user engagement over time.

#### SQL Code
```sql
-- Common Table Expression (CTE) to get the week of year for each date
WITH week_data AS (
    SELECT
        EXTRACT(year FROM ds) AS year,
        EXTRACT(week FROM ds) AS week,
        MAX(ds) AS week_ds
    FROM
        my_table
    GROUP BY 1, 2
),

-- Extracting relevant data
data AS (
    SELECT
        EXTRACT(year FROM ds) AS year,
        EXTRACT(week FROM ds) AS week,
        user_id
    FROM
        my_table
    GROUP BY 1, 2, 3
),

-- Joining data with the latest week information
events AS (
    SELECT
        week_ds,
        user_id
    FROM
        data
    JOIN week_data USING (year, week)
),

-- Creating user cohorts with the earliest week of activity
user_cohort AS (
    SELECT
        user_id,
        MIN(week_ds) AS cohort_week
    FROM
        events
    GROUP BY 1
),

-- Calculating cohort sizes
cohort_size AS (
    SELECT
        cohort_week,
        COUNT(DISTINCT user_id) AS cohort_size
    FROM
        user_cohort
    WHERE 
        cohort_week > {{day}}
    GROUP BY 1
),

-- Calculating cohort activity (active users per week)
cohort_activity AS (
    SELECT
        week_ds,
        cohort_week,
        COUNT(DISTINCT user_id) AS active_users
    FROM
        events
    JOIN user_cohort USING (user_id)
    WHERE 
        cohort_week > {{day}}
    GROUP BY 1, 2
)

-- Final query to calculate age, age_index, and retention rate
SELECT
    CONCAT(SUBSTRING(CAST(week_ds - cohort_week AS VARCHAR), 1, 2), ' day') AS age_index,
    cohort_week,
    CAST(TRIM(SUBSTRING(CAST(week_ds - cohort_week AS VARCHAR), 1, 2)) AS BIGINT) AS age,
    CAST(SUM(active_users) AS DOUBLE) / SUM(cohort_size) AS retention_rate
FROM
    cohort_activity
JOIN cohort_size USING (cohort_week)
WHERE
    -- remove the first week for each cohort
    week_ds > cohort_week 
    AND CAST(TRIM(SUBSTRING(CAST(week_ds - cohort_week AS VARCHAR), 1, 2)) AS BIGINT) % 7 = 0
GROUP BY 1, 2, 3
ORDER BY 2, 3
```

## Result
| age_index | cohort_week | age | retention_rate |
|-----------|-------------|-----|-----------------|
| 0 day     | 2022-01-01  | 0   | 1.0             |
| 7 day     | 2022-01-01  | 7   | 0.75            |
| 14 day    | 2022-01-01  | 14  | 0.6             |
| ...       | ...         | ... | ...             |

## Visualization

To create a pivot table visualization in Metabase and apply conditional formatting to highlight key insights, follow these steps:

1. **Select Table in Visualization:** Choose the "Table" visualization option in Metabase.
2. **Go to Table Options:** Navigate to the "Table Options" settings.
3. **Turn On Pivot Table Option:** Enable the "Pivot Table" option to organize your data effectively.
4. **Select Age Index in Pivot Column:** In the Pivot Table configuration, choose "age_index" as the column for pivoting.
5. **Select Retention Rate in Cell Column:** Specify "retention_rate" as the column to populate the cells of the pivot table.
6. **Click on Conditional Formatting Tab:** Access the "Conditional Formatting" tab to enhance visual interpretation.
7. **Click on Add a Rule:** Add a rule to define conditions for formatting based on specific criteria.
8. **Check Color Range in Formatting Style Section:** Within the formatting style section, verify the color range settings to ensure a clear representation of varying retention rates.

These steps will help you transform your cohort analysis results into a visually informative and easily interpretable pivot table with color-coded conditional formatting like this:


![cohort analysis visualization in metabase](https://github.com/mahdinasseri/SQL-Metabase-Codes/blob/main/Cohort-Analysis/Cohort-Analysis-Visualization.jpg)

## Getting Started
1. Ensure you have a database with the required data.
2. Execute the provided SQL code against your database.
3. Import the Metabase visualization files into your Metabase instance.

Feel free to explore, modify, and contribute to enhance the capabilities of this cohort analysis framework.
