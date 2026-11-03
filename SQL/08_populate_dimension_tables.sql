USE retail_price_intelligence;

-- Populate currency dimension
INSERT INTO dim_currency (
    currency_code,
    currency_name,
    is_unknown
)
SELECT DISTINCT
    COALESCE(NULLIF(TRIM(currency), ''), 'UNKNOWN'),
    NULL,
    CASE
        WHEN currency IS NULL OR TRIM(currency) = ''
        THEN TRUE
        ELSE FALSE
    END
FROM stg_open_prices
WHERE type = 'PRODUCT';

-- Populate product dimension
INSERT INTO dim_products (
    product_code
)
SELECT DISTINCT
    product_code
FROM stg_open_prices
WHERE type = 'PRODUCT'
  AND product_code IS NOT NULL;


  SELECT
    COUNT(*) AS total_currencies
FROM dim_currency;

SELECT
    COUNT(*) AS total_products
FROM dim_products;

SELECT *
FROM dim_currency
ORDER BY currency_code;

SELECT
    MAX(CHAR_LENGTH(product_name)) AS maximum_name_length,
    SUM(
        product_name IS NULL
        OR TRIM(product_name) = ''
    ) AS missing_or_blank_names
FROM stg_open_prices
WHERE type = 'PRODUCT';

SELECT COUNT(*) AS prefix_collision_groups
FROM (
    SELECT
        product_code,
        LEFT(TRIM(product_name), 255) AS name_prefix
    FROM stg_open_prices
    WHERE type = 'PRODUCT'
      AND product_name IS NOT NULL
      AND TRIM(product_name) <> ''
    GROUP BY
        product_code,
        LEFT(TRIM(product_name), 255)
    HAVING COUNT(DISTINCT TRIM(product_name)) > 1
) AS collisions;


SELECT COUNT(*) AS total_currencies
FROM dim_currency;

SELECT COUNT(*) AS total_products
FROM dim_products;

SELECT *
FROM dim_currency
ORDER BY currency_code;

INSERT INTO dim_product_names (
    product_id,
    product_name
)
SELECT DISTINCT
    dp.product_id,
    TRIM(stg.product_name)
FROM stg_open_prices stg
INNER JOIN dim_products dp
    ON stg.product_code = dp.product_code
WHERE stg.type = 'PRODUCT'
  AND stg.product_name IS NOT NULL
  AND TRIM(stg.product_name) <> '';

  SELECT COUNT(*) AS total_product_name_variants
FROM dim_product_names;


-- Validate product-name relationships

SELECT
    COUNT(*) AS total_name_variants,
    COUNT(DISTINCT product_id) AS products_with_names
FROM dim_product_names;

SELECT
    dp.product_code,
    pn.product_name
FROM dim_products dp
JOIN dim_product_names pn
    ON dp.product_id = pn.product_id
WHERE dp.product_code = '3017620422003'
ORDER BY pn.product_name;

SELECT
    COUNT(*) AS total_locations,
    COUNT(DISTINCT location_id) AS unique_locations
FROM stg_open_prices
WHERE location_id IS NOT NULL;



-- ============================================
-- 4. POPULATE LOCATION DIMENSION
-- ============================================

INSERT INTO dim_locations (
    location_id,
    location_osm_id,
    location_osm_type,
    location_name,
    city,
    country,
    country_code,
    postcode,
    latitude,
    longitude,
    location_website_url,
    location_source,
    is_geography_incomplete,
    has_osm_mapping_variation
)

SELECT
    ranked.location_id,
    ranked.location_osm_id,
    ranked.location_osm_type,
    ranked.location_osm_display_name,
    ranked.location_osm_address_city,
    ranked.location_osm_address_country,
    ranked.location_osm_address_country_code,
    ranked.location_osm_address_postcode,
    ranked.location_osm_lat,
    ranked.location_osm_lon,
    ranked.location_website_url,
    ranked.location_source,

    CASE
        WHEN ranked.location_osm_address_city IS NULL
          OR ranked.location_osm_address_country IS NULL
          OR ranked.location_osm_lat IS NULL
          OR ranked.location_osm_lon IS NULL
        THEN TRUE
        ELSE FALSE
    END,

    CASE
        WHEN variation.osm_id_count > 1 THEN TRUE
        ELSE FALSE
    END

FROM (

    SELECT
        stg.*,

        ROW_NUMBER() OVER (
            PARTITION BY stg.location_id
            ORDER BY
                (
                    (stg.location_osm_id IS NOT NULL) +
                    (stg.location_osm_display_name IS NOT NULL) +
                    (stg.location_osm_address_city IS NOT NULL) +
                    (stg.location_osm_address_country IS NOT NULL) +
                    (stg.location_osm_lat IS NOT NULL) +
                    (stg.location_osm_lon IS NOT NULL)
                ) DESC,
                stg.location_updated DESC,
                stg.location_created DESC
        ) AS row_num

    FROM stg_open_prices stg

    WHERE stg.location_id IS NOT NULL

) AS ranked

LEFT JOIN (

    SELECT
        location_id,
        COUNT(DISTINCT location_osm_id) AS osm_id_count

    FROM stg_open_prices

    WHERE location_id IS NOT NULL

    GROUP BY location_id

) AS variation

    ON ranked.location_id = variation.location_id

WHERE ranked.row_num = 1

ON DUPLICATE KEY UPDATE

    location_osm_id = VALUES(location_osm_id),
    location_osm_type = VALUES(location_osm_type),
    location_name = VALUES(location_name),
    city = VALUES(city),
    country = VALUES(country),
    country_code = VALUES(country_code),
    postcode = VALUES(postcode),
    latitude = VALUES(latitude),
    longitude = VALUES(longitude),
    location_website_url = VALUES(location_website_url),
    location_source = VALUES(location_source),
    is_geography_incomplete = VALUES(is_geography_incomplete),
    has_osm_mapping_variation = VALUES(has_osm_mapping_variation);

    -- Validate the location dimension

    SELECT
    COUNT(*) AS total_locations,
    COUNT(DISTINCT location_id) AS unique_location_ids,
    SUM(is_geography_incomplete) AS incomplete_locations,
    SUM(has_osm_mapping_variation) AS locations_with_osm_variation
FROM dim_locations;

SELECT *
FROM dim_locations
WHERE location_id = 4706;



-- ============================================
-- 5. POPULATE DATE DIMENSION
-- ============================================

SELECT
    @start_date AS start_date,
    @end_date AS end_date;

SET SESSION cte_max_recursion_depth = 10000;

INSERT INTO dim_date (
    date_key,
    full_date,
    day_number,
    month_number,
    month_name,
    quarter_number,
    year_number,
    day_of_week_number,
    day_name,
    is_weekend
)

WITH RECURSIVE calendar AS (

    -- Starting date
    SELECT DATE('2010-07-08') AS calendar_date

    UNION ALL

    -- Generate the next date
    SELECT DATE_ADD(calendar_date, INTERVAL 1 DAY)
    FROM calendar
    WHERE calendar_date < DATE('2026-10-30')

)

SELECT
    CAST(DATE_FORMAT(calendar_date, '%Y%m%d') AS UNSIGNED),
    calendar_date,
    DAY(calendar_date),
    MONTH(calendar_date),
    MONTHNAME(calendar_date),
    QUARTER(calendar_date),
    YEAR(calendar_date),
    DAYOFWEEK(calendar_date),
    DAYNAME(calendar_date),

    CASE
        WHEN DAYOFWEEK(calendar_date) IN (1, 7)
        THEN TRUE
        ELSE FALSE
    END

FROM calendar;

SELECT
    COUNT(*) AS total_calendar_days,
    MIN(full_date) AS first_date,
    MAX(full_date) AS last_date,
    COUNT(DISTINCT date_key) AS unique_date_keys
FROM dim_date;




-- All five dimensions — final validation

SELECT 'dim_products' AS table_name,
       COUNT(*) AS total_records
FROM dim_products

UNION ALL

SELECT 'dim_product_names',
       COUNT(*)
FROM dim_product_names

UNION ALL

SELECT 'dim_locations',
       COUNT(*)
FROM dim_locations

UNION ALL

SELECT 'dim_date',
       COUNT(*)
FROM dim_date

UNION ALL

SELECT 'dim_currency',
       COUNT(*)
FROM dim_currency;

SELECT *
FROM dim_currency
WHERE is_unknown = TRUE;


SELECT 'dim_products' AS table_name,
       COUNT(*) AS total_records
FROM dim_products

UNION ALL

SELECT 'dim_product_names', COUNT(*)
FROM dim_product_names

UNION ALL

SELECT 'dim_locations', COUNT(*)
FROM dim_locations

UNION ALL

SELECT 'dim_date', COUNT(*)
FROM dim_date

UNION ALL

SELECT 'dim_currency', COUNT(*)
FROM dim_currency;


SELECT
    COUNT(DISTINCT NULLIF(UPPER(TRIM(currency)), '')) AS distinct_product_currencies
FROM stg_open_prices
WHERE type = 'PRODUCT';

SELECT
    type,
    COUNT(DISTINCT NULLIF(UPPER(TRIM(currency)), '')) AS distinct_currencies
FROM stg_open_prices
GROUP BY type;

SELECT
    type,
    COUNT(DISTINCT NULLIF(UPPER(TRIM(currency)), '')) AS distinct_currencies
FROM stg_open_prices
GROUP BY type;


-- Verify the dimension contains 94 codes plus UNKNOWN:

SELECT
    COUNT(*) AS total_members,
    SUM(is_unknown = 1) AS unknown_members,
    SUM(is_unknown = 0) AS currency_members
FROM dim_currency;

SELECT
    UPPER(TRIM(currency)) AS normalized_currency,
    COUNT(DISTINCT currency) AS source_variations,
    COUNT(*) AS observations
FROM stg_open_prices
WHERE type = 'PRODUCT'
  AND currency IS NOT NULL
  AND TRIM(currency) <> ''
GROUP BY UPPER(TRIM(currency))
HAVING COUNT(DISTINCT currency) > 1;



USE retail_price_intelligence;

-- 1. Check existing fact table names
SHOW TABLES LIKE 'fact_price_observations%';

-- 2. Check whether any PRODUCT observations have missing prices
SELECT
    COUNT(*) AS total_product_records,
    SUM(price IS NULL) AS missing_prices,
    SUM(price = 0) AS zero_prices,
    SUM(product_code IS NULL) AS missing_product_codes
FROM stg_open_prices
WHERE type = 'PRODUCT';

-- 3. Check whether location_id = 0 already exists in source
SELECT COUNT(*) AS existing_zero_location_ids
FROM stg_open_prices
WHERE location_id = 0;

DESCRIBE dim_products;
DESCRIBE dim_locations;
DESCRIBE dim_date;
DESCRIBE dim_currency;
DESCRIBE stg_open_prices;



INSERT INTO dim_locations (
    location_id,
    location_name,
    is_geography_incomplete,
    has_osm_mapping_variation
)
SELECT
    0,
    'Unknown location',
    1,
    0
WHERE NOT EXISTS (
    SELECT 1
    FROM dim_locations
    WHERE location_id = 0
);


SELECT *
FROM dim_locations
WHERE location_id = 0;