SELECT
    (SELECT COUNT(*)
     FROM silver.user_ltv_vw) AS silver_users,

    (SELECT SUM(user_count)
     FROM gold.monthly_ltv_cac_vw) AS gold_monthly_users,

    (SELECT ROUND(SUM(predicted_ltv), 2)
     FROM silver.user_ltv_vw) AS silver_ltv,

    (SELECT ROUND(SUM(total_predicted_ltv), 2)
     FROM gold.monthly_ltv_cac_vw) AS gold_monthly_ltv,

    (SELECT ROUND(SUM(acquisition_cost), 2)
     FROM silver.user_cac_vw) AS silver_cost,

    (SELECT ROUND(SUM(total_acquisition_cost), 2)
     FROM gold.monthly_ltv_cac_vw) AS gold_monthly_cost;

SELECT
    'daily' AS cohort_grain,
    SUM(user_count) AS user_count,
    SUM(total_predicted_ltv) AS total_predicted_ltv,
    SUM(total_acquisition_cost) AS total_acquisition_cost
FROM gold.daily_ltv_cac_vw

UNION ALL

SELECT
    'weekly',
    SUM(user_count),
    SUM(total_predicted_ltv),
    SUM(total_acquisition_cost)
FROM gold.weekly_ltv_cac_vw

UNION ALL

SELECT
    'monthly',
    SUM(user_count),
    SUM(total_predicted_ltv),
    SUM(total_acquisition_cost)
FROM gold.monthly_ltv_cac_vw

UNION ALL

SELECT
    'yearly',
    SUM(user_count),
    SUM(total_predicted_ltv),
    SUM(total_acquisition_cost)
FROM gold.yearly_ltv_cac_vw;
	 