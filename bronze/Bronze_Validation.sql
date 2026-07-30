SELECT
    'users_daily_snapshot' AS table_name,
    COUNT(*) AS row_count
FROM bronze.users_daily_snapshot

UNION ALL

SELECT
    'listings_daily_snapshot',
    COUNT(*)
FROM bronze.listings_daily_snapshot

UNION ALL

SELECT
    'listing_predictions',
    COUNT(*)
FROM bronze.listing_predictions

UNION ALL

SELECT
    'reservations',
    COUNT(*)
FROM bronze.reservations

UNION ALL

SELECT
    'ad_spend_daily',
    COUNT(*)
FROM bronze.ad_spend_daily

ORDER BY table_name;

-- Null checks
SELECT
    COUNT(*) FILTER (WHERE user_id IS NULL) AS null_user_id,
    COUNT(*) FILTER (WHERE join_date IS NULL) AS null_join_date,
    COUNT(*) FILTER (WHERE snapshot_date IS NULL) AS null_snapshot_date,
    COUNT(*) FILTER (
        WHERE acquisition_channel IS NULL
           OR TRIM(acquisition_channel) = ''
    ) AS unattributed_users
FROM bronze.users_daily_snapshot;

-- Duplicate snapshot grain checks
SELECT
    user_id,
    snapshot_date,
    COUNT(*) AS duplicate_count
FROM bronze.users_daily_snapshot
GROUP BY user_id, snapshot_date
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

SELECT
    listing_id,
    snapshot_date,
    COUNT(*) AS duplicate_count
FROM bronze.listings_daily_snapshot
GROUP BY listing_id, snapshot_date
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Prediction uniqueness
SELECT
    listing_id,
    COUNT(*) AS prediction_count
FROM bronze.listing_predictions
GROUP BY listing_id
HAVING COUNT(*) > 1;

-- Reservation key uniqueness
SELECT
    reservation_id,
    COUNT(*) AS reservation_count
FROM bronze.reservations
GROUP BY reservation_id
HAVING COUNT(*) > 1;

-- Date ranges
SELECT
    MIN(join_date) AS earliest_join_date,
    MAX(join_date) AS latest_join_date,
    MIN(snapshot_date) AS earliest_snapshot,
    MAX(snapshot_date) AS latest_snapshot
FROM bronze.users_daily_snapshot;

SELECT
    MIN("date") AS earliest_spend_date,
    MAX("date") AS latest_spend_date,
    SUM(spend_amount) AS total_spend,
    SUM(attributed_signups) AS total_attributed_signups
FROM bronze.ad_spend_daily;