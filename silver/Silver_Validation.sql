SELECT 'silver.users' AS table_name, COUNT(*) AS row_count
FROM silver.users

UNION ALL

SELECT 'silver.listings', COUNT(*)
FROM silver.listings

UNION ALL

SELECT 'silver.listing_ltv', COUNT(*)
FROM silver.listing_ltv

UNION ALL

SELECT 'silver.ad_spend_daily', COUNT(*)
FROM silver.ad_spend_daily;

SELECT
    COUNT(*) FILTER (WHERE is_unattributed) AS unattributed_users,
    COUNT(*) FILTER (
        WHERE acquisition_channel <> 'unattributed'
    ) AS attributed_users
FROM silver.users;

SELECT
    COUNT(*) AS orphan_predictions
FROM silver.listing_ltv
WHERE is_orphan_prediction = TRUE;

SELECT
    COUNT(*) AS orphan_hosts
FROM silver.listings l
LEFT JOIN silver.users u
    ON l.host_user_id = u.user_id
WHERE u.user_id IS NULL;

SELECT
    acquisition_channel,
    COUNT(*) AS users
FROM silver.users
GROUP BY acquisition_channel
ORDER BY users DESC;

-------

--1. Row count validation
SELECT
    'user_ltv_vw' AS view_name,
    COUNT(*) AS row_count,
    COUNT(DISTINCT user_id) AS distinct_users
FROM silver.user_ltv_vw

UNION ALL

SELECT
    'user_cac_vw',
    COUNT(*),
    COUNT(DISTINCT user_id)
FROM silver.user_cac_vw;

--2. Validate users without listings
SELECT
    COUNT(*) AS users_without_listings,
    SUM(predicted_ltv) AS total_predicted_ltv
FROM silver.user_ltv_vw
WHERE listing_count = 0;

--3. Reconcile listing LTV
SELECT
    (
        SELECT ROUND(SUM(host_ltv),2)
        FROM silver.listing_ltv
        WHERE host_user_id IN (
            SELECT user_id
            FROM silver.users
        )
    ) AS listing_ltv,

    (
        SELECT ROUND(SUM(predicted_ltv),2)
        FROM silver.user_ltv_vw
    ) AS user_ltv;

--4. Validate free acquisition channels
SELECT
    acquisition_channel,
    COUNT(*) AS users,
    SUM(acquisition_cost) AS total_cost
FROM silver.user_cac_vw
WHERE acquisition_channel IN (
    'organic',
    'referral',
    'unattributed'
)
GROUP BY acquisition_channel
ORDER BY acquisition_channel;

--5. Missing spend matches
SELECT
    acquisition_channel,
    COUNT(*) AS users_missing_spend_match
FROM silver.user_cac_vw
WHERE is_missing_spend_match = TRUE
GROUP BY acquisition_channel
ORDER BY users_missing_spend_match DESC;

--6. One-to-one join check
SELECT
    COUNT(*) AS matched_users
FROM silver.user_ltv_vw l
INNER JOIN silver.user_cac_vw c
    ON l.user_id = c.user_id;