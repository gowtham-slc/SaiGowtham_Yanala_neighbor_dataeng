/* ============================================================
   BRONZE LAYER
   Purpose:
   - Preserve source structure and column names
   - Apply only basic PostgreSQL-compatible data types
   - No renaming, deduplication, or business transformations
   ============================================================ */

DROP TABLE IF EXISTS bronze.users_daily_snapshot;
DROP TABLE IF EXISTS bronze.listings_daily_snapshot;
DROP TABLE IF EXISTS bronze.listing_predictions;
DROP TABLE IF EXISTS bronze.reservations;
DROP TABLE IF EXISTS bronze.ad_spend_daily;


/* ------------------------------------------------------------
   Source: users_daily_snapshot.csv

   Sparse user snapshots:
   - Row created on join date
   - Row created when state/status changes
   - Final snapshot row on the last dataset date
   ------------------------------------------------------------ */
CREATE TABLE bronze.users_daily_snapshot (
    user_id              VARCHAR(20),
    join_date            DATE,
    state                VARCHAR(2),
    status               VARCHAR(20),
    acquisition_channel  VARCHAR(50),
    snapshot_date        DATE
);


/* ------------------------------------------------------------
   Source: listings_daily_snapshot.csv

   Sparse listing snapshots:
   - Listing may have multiple rows over time
   - listing_id is therefore not unique in Bronze
   ------------------------------------------------------------ */
CREATE TABLE bronze.listings_daily_snapshot (
    listing_id       VARCHAR(20),
    host_user_id     VARCHAR(20),
    status           VARCHAR(20),
    city             VARCHAR(100),
    state            VARCHAR(2),
    monthly_price    NUMERIC(14, 2),
    listed_date      DATE,
    snapshot_date    DATE
);


/* ------------------------------------------------------------
   Source: listing_predictions.csv

   One prediction per listing in this dataset
   ------------------------------------------------------------ */
CREATE TABLE bronze.listing_predictions (
    prediction_id    VARCHAR(20),
    listing_id       VARCHAR(20),
    host_ltv         NUMERIC(14, 2),
    model_version    VARCHAR(20),
    predicted_at     TIMESTAMP
);


/* ------------------------------------------------------------
   Source: reservations.csv

   One row per reservation
   ------------------------------------------------------------ */
CREATE TABLE bronze.reservations (
    reservation_id   VARCHAR(20),
    user_id          VARCHAR(20),
    listing_id       VARCHAR(20),
    reservation_date DATE,
    duration_months  INTEGER,
    amount           NUMERIC(14, 2)
);


/* ------------------------------------------------------------
   Source: ad_spend_daily.csv

   "date" is preserved because that is the exact source name.
   Double quotes are used because DATE is also a PostgreSQL
   data type keyword.
   ------------------------------------------------------------ */
CREATE TABLE bronze.ad_spend_daily (
    "date"                DATE,
    campaign_id           VARCHAR(20),
    campaign_name         VARCHAR(100),
    channel               VARCHAR(50),
    spend_amount          NUMERIC(14, 2),
    impressions           BIGINT,
    attributed_signups    INTEGER
);