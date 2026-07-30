--1. Daily View
CREATE OR REPLACE VIEW gold.daily_ltv_cac_vw AS

SELECT
    l.join_date AS cohort_period,
    l.acquisition_channel,

    COUNT(*) AS user_count,

    SUM(l.listing_count) AS listing_count,

  SUM(l.predicted_ltv) AS total_predicted_ltv,

SUM(c.acquisition_cost) AS total_acquisition_cost,

    ROUND(AVG(l.predicted_ltv),2) AS average_predicted_ltv_per_user,

    ROUND(AVG(c.acquisition_cost),4) AS average_acquisition_cost_per_user,

    CASE
    WHEN COUNT(*) FILTER (
        WHERE c.is_missing_spend_match = TRUE
    ) > 0
    THEN NULL

    ELSE ROUND(
        SUM(l.predicted_ltv)
        / NULLIF(SUM(c.acquisition_cost), 0),
        4
    )
END AS ltv_cac_ratio,
CASE
    WHEN COUNT(*) FILTER (
        WHERE c.is_missing_spend_match = TRUE
    ) > 0
    THEN 'incomplete_spend_coverage'
    ELSE 'complete'
END AS data_quality_status,
    COUNT(*)
        FILTER (
            WHERE c.is_missing_spend_match = TRUE
        ) AS missing_spend_match_users

FROM silver.user_ltv_vw l
INNER JOIN silver.user_cac_vw c
    ON l.user_id = c.user_id

GROUP BY
    l.join_date,
    l.acquisition_channel

ORDER BY
    cohort_period,
    acquisition_channel;

--2. Weekly View
	CREATE OR REPLACE VIEW gold.weekly_ltv_cac_vw AS

SELECT
    DATE_TRUNC('week', l.join_date)::DATE AS cohort_period,
    l.acquisition_channel,

    COUNT(*) AS user_count,

    SUM(l.listing_count) AS listing_count,

SUM(l.predicted_ltv) AS total_predicted_ltv,

SUM(c.acquisition_cost) AS total_acquisition_cost,

    ROUND(AVG(l.predicted_ltv),2) AS average_predicted_ltv_per_user,

    ROUND(AVG(c.acquisition_cost),4) AS average_acquisition_cost_per_user,

    CASE
    WHEN COUNT(*) FILTER (
        WHERE c.is_missing_spend_match = TRUE
    ) > 0
    THEN NULL

    ELSE ROUND(
        SUM(l.predicted_ltv)
        / NULLIF(SUM(c.acquisition_cost), 0),
        4
    )
END AS ltv_cac_ratio,
CASE
    WHEN COUNT(*) FILTER (
        WHERE c.is_missing_spend_match = TRUE
    ) > 0
    THEN 'incomplete_spend_coverage'
    ELSE 'complete'
END AS data_quality_status,
    COUNT(*)
        FILTER (
            WHERE c.is_missing_spend_match = TRUE
        ) AS missing_spend_match_users

FROM silver.user_ltv_vw l
JOIN silver.user_cac_vw c
ON l.user_id = c.user_id

GROUP BY
    DATE_TRUNC('week', l.join_date),
    l.acquisition_channel

ORDER BY
    cohort_period,
    acquisition_channel;

--3. Monthly View

CREATE OR REPLACE VIEW gold.monthly_ltv_cac_vw AS

SELECT
    DATE_TRUNC('month', l.join_date)::DATE AS cohort_period,
    l.acquisition_channel,

    COUNT(*) AS user_count,

    SUM(l.listing_count) AS listing_count,

SUM(l.predicted_ltv) AS total_predicted_ltv,

SUM(c.acquisition_cost) AS total_acquisition_cost,

    ROUND(AVG(l.predicted_ltv),2) AS average_predicted_ltv_per_user,

    ROUND(AVG(c.acquisition_cost),4) AS average_acquisition_cost_per_user,

    CASE
    WHEN COUNT(*) FILTER (
        WHERE c.is_missing_spend_match = TRUE
    ) > 0
    THEN NULL

    ELSE ROUND(
        SUM(l.predicted_ltv)
        / NULLIF(SUM(c.acquisition_cost), 0),
        4
    )
END AS ltv_cac_ratio,
CASE
    WHEN COUNT(*) FILTER (
        WHERE c.is_missing_spend_match = TRUE
    ) > 0
    THEN 'incomplete_spend_coverage'
    ELSE 'complete'
END AS data_quality_status,
    COUNT(*)
        FILTER (
            WHERE c.is_missing_spend_match = TRUE
        ) AS missing_spend_match_users

FROM silver.user_ltv_vw l
JOIN silver.user_cac_vw c
ON l.user_id = c.user_id

GROUP BY
    DATE_TRUNC('month', l.join_date),
    l.acquisition_channel

ORDER BY
    cohort_period,
    acquisition_channel;

-- 4. Yearly View

CREATE OR REPLACE VIEW gold.yearly_ltv_cac_vw AS

SELECT
    DATE_TRUNC('year', l.join_date)::DATE AS cohort_period,
    l.acquisition_channel,

    COUNT(*) AS user_count,

    SUM(l.listing_count) AS listing_count,

SUM(l.predicted_ltv) AS total_predicted_ltv,

SUM(c.acquisition_cost) AS total_acquisition_cost,

    ROUND(AVG(l.predicted_ltv),2) AS average_predicted_ltv_per_user,

    ROUND(AVG(c.acquisition_cost),4) AS average_acquisition_cost_per_user,

    CASE
    WHEN COUNT(*) FILTER (
        WHERE c.is_missing_spend_match = TRUE
    ) > 0
    THEN NULL

    ELSE ROUND(
        SUM(l.predicted_ltv)
        / NULLIF(SUM(c.acquisition_cost), 0),
        4
    )
END AS ltv_cac_ratio,
CASE
    WHEN COUNT(*) FILTER (
        WHERE c.is_missing_spend_match = TRUE
    ) > 0
    THEN 'incomplete_spend_coverage'
    ELSE 'complete'
END AS data_quality_status,
    COUNT(*)
        FILTER (
            WHERE c.is_missing_spend_match = TRUE
        ) AS missing_spend_match_users

FROM silver.user_ltv_vw l
JOIN silver.user_cac_vw c
ON l.user_id = c.user_id

GROUP BY
    DATE_TRUNC('year', l.join_date),
    l.acquisition_channel

ORDER BY
    cohort_period,
    acquisition_channel;

--Final Presentation layer:
SELECT
    'daily' AS cohort_grain,
    SUM(user_count) AS user_count,
    ROUND(SUM(total_predicted_ltv), 2) AS total_predicted_ltv,
    ROUND(SUM(total_acquisition_cost), 2) AS total_acquisition_cost
FROM gold.daily_ltv_cac_vw

UNION ALL

SELECT
    'weekly',
    SUM(user_count),
    ROUND(SUM(total_predicted_ltv), 2),
    ROUND(SUM(total_acquisition_cost), 2)
FROM gold.weekly_ltv_cac_vw

UNION ALL

SELECT
    'monthly',
    SUM(user_count),
    ROUND(SUM(total_predicted_ltv), 2),
    ROUND(SUM(total_acquisition_cost), 2)
FROM gold.monthly_ltv_cac_vw

UNION ALL

SELECT
    'yearly',
    SUM(user_count),
    ROUND(SUM(total_predicted_ltv), 2),
    ROUND(SUM(total_acquisition_cost), 2)
FROM gold.yearly_ltv_cac_vw;
	
