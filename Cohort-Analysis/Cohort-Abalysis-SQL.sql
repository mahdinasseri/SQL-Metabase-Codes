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
