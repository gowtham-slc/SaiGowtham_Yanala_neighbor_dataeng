# Setup Instructions

These steps reproduce the solution using PostgreSQL and pgAdmin in approximately five minutes after the supplied CSV files are available.

## Prerequisites

- PostgreSQL 14 or later
- pgAdmin 4
- The five original CSV files supplied with the assessment

Download pgAdmin from:

https://www.pgadmin.org/download/

## 1. Create the database

1. Open pgAdmin and connect to a local PostgreSQL server.
2. In the Browser panel, right-click **Databases**.
3. Select **Create → Database**.
4. Enter the database name:

   `neighbor_assessment`

5. Click **Save**.

## 2. Create the schemas and Bronze tables

1. Select the `neighbor_assessment` database.
2. Open **Tools → Query Tool**.
3. Open and run:

   `bronze/bronze.sql` --in bronze folder open bronze table creation.sql

This script creates:

- `bronze`
- `silver`
- `gold`

It also creates the five Bronze tables required for source ingestion.

## 3. Import the supplied CSV files

In pgAdmin, navigate to:

`Databases → neighbor_assessment → Schemas → bronze → Tables`

For each table below:

1. Right-click the table.
2. Select **Import/Export Data**.
3. Set **Import/Export** to `Import`.
4. Select the corresponding CSV file.
5. Set **Format** to `csv`.
6. Set **Header** to `Yes`.
7. Set **Delimiter** to `,`.
8. Click **OK**.

Import mappings:

| Supplied CSV | Bronze table |
|---|---|
| `users_daily_snapshot.csv` | `bronze.users_daily_snapshot` |
| `listings_daily_snapshot.csv` | `bronze.listings_daily_snapshot` |
| `listing_predictions.csv` | `bronze.listing_predictions` |
| `reservations.csv` | `bronze.reservations` |
| `ad_spend_daily.csv` | `bronze.ad_spend_daily` |

## 4. Build the Silver layer

Open a new Query Tool window and run:

`silver/silver.sql`

This creates the cleaned and conformed Silver tables and user-level LTV and CAC views.

## 5. Build the Gold layer

Run:

`gold/gold.sql`

This creates:

- `gold.daily_ltv_cac_vw`
- `gold.weekly_ltv_cac_vw`
- `gold.monthly_ltv_cac_vw`
- `gold.yearly_ltv_cac_vw`

## 6. Validate the results

Run the scripts in this order:

1. `bronze/bronze_validation.sql`
2. `silver/silver_validation.sql`
3. `gold/gold_validation.sql`

Expected reconciled totals across all Gold reporting grains:

| Measure | Expected result |
|---|---:|
| Users | 14,995 |
| Predicted LTV | 146,364,176.01 |
| Acquisition cost | 22,917,606.881642 |

Daily, weekly, monthly, and yearly views should return identical aggregate totals.
