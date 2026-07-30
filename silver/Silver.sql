/* ============================================================
   SILVER LAYER
   Purpose:
   - Resolve sparse snapshots to one current row per entity
   - Standardize text values
   - Connect listing predictions to host users
   - Aggregate advertising spend to date/channel grain
   ============================================================ */

DROP TABLE IF EXISTS silver.listing_ltv;
DROP TABLE IF EXISTS silver.listings;
DROP TABLE IF EXISTS silver.users;
DROP TABLE IF EXISTS silver.ad_spend_daily;


/* ------------------------------------------------------------
   1. USERS
   Latest available snapshot per user
   ------------------------------------------------------------ */
CREATE TABLE silver.users AS
WITH ranked_users AS (
    SELECT
        user_id,
        join_date,
        state,
        status,
        acquisition_channel,
        snapshot_date,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY snapshot_date DESC
        ) AS row_num
    FROM bronze.users_daily_snapshot
)
SELECT
    user_id,
    join_date,
    UPPER(TRIM(state)) AS state,
    LOWER(TRIM(status)) AS status,

    CASE
        WHEN acquisition_channel IS NULL
          OR TRIM(acquisition_channel) = ''
        THEN 'unattributed'
        ELSE LOWER(TRIM(acquisition_channel))
    END AS acquisition_channel,

    snapshot_date AS latest_snapshot_date,

    CASE
        WHEN acquisition_channel IS NULL
          OR TRIM(acquisition_channel) = ''
        THEN TRUE
        ELSE FALSE
    END AS is_unattributed

FROM ranked_users
WHERE row_num = 1;

ALTER TABLE silver.users
ADD CONSTRAINT pk_silver_users PRIMARY KEY (user_id);


/* ------------------------------------------------------------
   2. LISTINGS
   Latest available snapshot per listing
   ------------------------------------------------------------ */
CREATE TABLE silver.listings AS
WITH ranked_listings AS (
    SELECT
        listing_id,
        host_user_id,
        status,
        city,
        state,
        monthly_price,
        listed_date,
        snapshot_date,
        ROW_NUMBER() OVER (
            PARTITION BY listing_id
            ORDER BY snapshot_date DESC
        ) AS row_num
    FROM bronze.listings_daily_snapshot
)
SELECT
    listing_id,
    host_user_id,
    LOWER(TRIM(status)) AS status,
    TRIM(city) AS city,
    UPPER(TRIM(state)) AS state,
    monthly_price,
    listed_date,
    snapshot_date AS latest_snapshot_date
FROM ranked_listings
WHERE row_num = 1;

ALTER TABLE silver.listings
ADD CONSTRAINT pk_silver_listings PRIMARY KEY (listing_id);


/* ------------------------------------------------------------
   3. LISTING LTV
   Connect each predicted listing value to its host
   ------------------------------------------------------------ */
CREATE TABLE silver.listing_ltv AS
SELECT
    p.prediction_id,
    p.listing_id,
    l.host_user_id,
    p.host_ltv,
    p.model_version,
    p.predicted_at,

    CASE
        WHEN l.listing_id IS NULL THEN TRUE
        ELSE FALSE
    END AS is_orphan_prediction

FROM bronze.listing_predictions p
LEFT JOIN silver.listings l
    ON p.listing_id = l.listing_id;

ALTER TABLE silver.listing_ltv
ADD CONSTRAINT pk_silver_listing_ltv PRIMARY KEY (prediction_id);


/* ------------------------------------------------------------
   4. AD SPEND
   Aggregate campaign-level records to date/channel grain
   ------------------------------------------------------------ */
CREATE TABLE silver.ad_spend_daily AS
SELECT
    "date" AS spend_date,
    LOWER(TRIM(channel)) AS acquisition_channel,
    SUM(spend_amount) AS spend_amount,
    SUM(impressions) AS impressions,
    SUM(attributed_signups) AS attributed_signups,

    CASE
        WHEN SUM(attributed_signups) > 0
        THEN SUM(spend_amount) / SUM(attributed_signups)
        ELSE NULL
    END AS cac_per_attributed_signup

FROM bronze.ad_spend_daily
GROUP BY
    "date",
    LOWER(TRIM(channel));

ALTER TABLE silver.ad_spend_daily
ADD CONSTRAINT pk_silver_ad_spend_daily
PRIMARY KEY (spend_date, acquisition_channel);

----
----
CREATE OR REPLACE VIEW silver.user_ltv_vw AS
WITH host_ltv AS (
    SELECT
        host_user_id AS user_id,
        COUNT(DISTINCT listing_id) AS listing_count,
        SUM(host_ltv) AS predicted_ltv
    FROM silver.listing_ltv
    WHERE host_user_id IS NOT NULL
      AND is_orphan_prediction = FALSE
    GROUP BY host_user_id
)
SELECT
    u.user_id,
    u.join_date,
    u.acquisition_channel,
    COALESCE(h.listing_count, 0) AS listing_count,
    COALESCE(h.predicted_ltv, 0.00)::NUMERIC(18,2) AS predicted_ltv
FROM silver.users u
LEFT JOIN host_ltv h
    ON u.user_id = h.user_id;


CREATE OR REPLACE VIEW silver.user_cac_vw AS
SELECT
    u.user_id,
    u.join_date,
    u.acquisition_channel,

    u.acquisition_channel NOT IN (
        'organic',
        'referral',
        'unattributed'
    ) AS is_paid_acquisition,

    CASE
        WHEN u.acquisition_channel IN (
            'organic',
            'referral',
            'unattributed'
        )
        THEN 0.00
        ELSE COALESCE(s.cac_per_attributed_signup, 0.00)
    END::NUMERIC(18,6) AS acquisition_cost,

    s.spend_amount AS matched_daily_channel_spend,
    s.attributed_signups AS matched_attributed_signups,

    CASE
        WHEN u.acquisition_channel NOT IN (
            'organic',
            'referral',
            'unattributed'
        )
        AND s.spend_date IS NULL
        THEN TRUE
        ELSE FALSE
    END AS is_missing_spend_match

FROM silver.users u
LEFT JOIN silver.ad_spend_daily s
    ON u.join_date = s.spend_date
   AND u.acquisition_channel = s.acquisition_channel;