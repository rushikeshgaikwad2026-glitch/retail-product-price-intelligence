-- Count distinct product-code/name combinations

SELECT
    COUNT(*) AS unique_code_name_combinations
FROM (
    SELECT product_code, product_name
    FROM stg_open_prices
    WHERE `type` = 'PRODUCT'
    GROUP BY product_code, product_name
) AS product_pairs;

--  Inspect one product with many names
SELECT
    product_code,
    product_name,
    COUNT(*) AS observations
FROM stg_open_prices
WHERE product_code = '3017620422003'
GROUP BY product_code, product_name
ORDER BY observations DESC;

-- Check location ID consistency
SELECT
    location_id,
    COUNT(*) AS observations,
    COUNT(DISTINCT location_osm_id) AS osm_id_count,
    COUNT(DISTINCT location_osm_address_country) AS country_count,
    COUNT(DISTINCT location_osm_address_city) AS city_count
FROM stg_open_prices
WHERE location_id IS NOT NULL
GROUP BY location_id
HAVING
    COUNT(DISTINCT location_osm_id) > 1
    OR COUNT(DISTINCT location_osm_address_country) > 1
    OR COUNT(DISTINCT location_osm_address_city) > 1
ORDER BY observations DESC
LIMIT 20;

-- Check missing location details
SELECT
    SUM(location_id IS NULL) AS missing_location_id,
    SUM(location_osm_id IS NULL) AS missing_osm_id,
    SUM(location_osm_address_country IS NULL) AS missing_country,
    SUM(location_osm_address_city IS NULL) AS missing_city,
    SUM(location_osm_lat IS NULL) AS missing_latitude,
    SUM(location_osm_lon IS NULL) AS missing_longitude
FROM stg_open_prices;

-- Inspect location ID 4706
SELECT DISTINCT
    location_id,
    location_osm_id,
    location_osm_type,
    location_osm_display_name,
    location_osm_address_city,
    location_osm_address_country,
    location_osm_lat,
    location_osm_lon,
    location_website_url,
    location_source,
    location_updated
FROM stg_open_prices
WHERE location_id = 4706
ORDER BY location_updated DESC;

-- Understand missing geography overlap

SELECT
    COUNT(*) AS total_records,

    SUM(location_osm_id IS NULL) AS missing_osm_id,

    SUM(location_osm_address_country IS NULL) AS missing_country,

    SUM(location_osm_lat IS NULL) AS missing_latitude,

    SUM(location_osm_lon IS NULL) AS missing_longitude,

    SUM(
        location_osm_id IS NULL
        AND location_osm_address_country IS NULL
    ) AS missing_osm_and_country,

    SUM(
        location_osm_address_city IS NULL
        AND location_osm_address_country IS NULL
    ) AS missing_city_and_country

FROM stg_open_prices;


-- Final Check -

SELECT
    COUNT(*) AS total_product_observations,
    SUM(product_name IS NULL) AS missing_product_names,
    SUM(TRIM(product_name) = '') AS blank_product_names,
    COUNT(DISTINCT product_code) AS unique_product_codes
FROM stg_open_prices
WHERE type = 'PRODUCT';

-- Data Coverage -

SELECT
    MIN(DATE(date)) AS first_observation_date,
    MAX(DATE(date)) AS last_observation_date,
    COUNT(DISTINCT DATE(date)) AS unique_observation_dates,
    SUM(date IS NULL) AS missing_dates
FROM stg_open_prices
WHERE type = 'PRODUCT';

-- Currency Coverage -
SELECT
    currency,
    COUNT(*) AS observation_count
FROM stg_open_prices
WHERE type = 'PRODUCT'
GROUP BY currency
ORDER BY observation_count DESC;

SELECT
    COUNT(*) AS existing_records
FROM fact_price_observations;

DESCRIBE fact_price_observations;

USE retail_price_intelligence;

RENAME TABLE
    fact_price_observations
TO
    fact_price_observations_prototype;

    SHOW TABLES;

SELECT COUNT(*) AS prototype_records
FROM fact_price_observations_prototype;