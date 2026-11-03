-- Verifying Total Records
USE retail_price_intelligence;

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT id) AS unique_ids
FROM stg_open_prices;

--- Verifying the ETL batch
SELECT
    etl_batch_id,
    COUNT(*) AS records_loaded,
    MIN(loaded_at) AS first_loaded_at,
    MAX(loaded_at) AS last_loaded_at
FROM stg_open_prices
GROUP BY etl_batch_id;

-- Verify Observation Types -

SELECT
    `type`,
    COUNT(*) AS total_observations
FROM stg_open_prices
GROUP BY `type`;

-- Quality Flags Verification

SELECT
    SUM(zero_price_flag = 1) AS zero_price_records,
    SUM(missing_date_flag = 1) AS missing_date_records,
    SUM(price_is_discounted = 1) AS discounted_records
FROM stg_open_prices;

-- Actual Record Inspection

SELECT
    id,
    product_code,
    product_name,
    price,
    currency,
    `date`,
    location_osm_address_country,
    discount_percentage
FROM stg_open_prices
LIMIT 10;