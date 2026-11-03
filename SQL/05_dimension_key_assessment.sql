-- Product key assessment

SELECT
    COUNT(*) AS product_observations,
    COUNT(DISTINCT product_code) AS unique_product_codes,
    SUM(product_code IS NULL) AS missing_product_codes,
    COUNT(DISTINCT product_name) AS unique_product_names
FROM stg_open_prices
WHERE `type` = 'PRODUCT';

-- Check duplicate product codes
SELECT
    product_code,
    COUNT(*) AS observation_count,
    COUNT(DISTINCT product_name) AS different_product_names
FROM stg_open_prices
WHERE `type` = 'PRODUCT'
GROUP BY product_code
HAVING COUNT(DISTINCT product_name) > 1
ORDER BY different_product_names DESC
LIMIT 20;


-- Location key assessment

SELECT
    COUNT(*) AS total_observations,
    COUNT(DISTINCT location_id) AS unique_location_ids,
    SUM(location_id IS NULL) AS missing_location_ids,
    COUNT(DISTINCT location_osm_id) AS unique_osm_ids
FROM stg_open_prices;

-- Currency distribution
SELECT
    currency,
    COUNT(*) AS observation_count
FROM stg_open_prices
GROUP BY currency
ORDER BY observation_count DESC;

-- Category distribution-

SELECT
    category_tag,
    COUNT(*) AS category_observations
FROM stg_open_prices
WHERE `type` = 'CATEGORY'
GROUP BY category_tag
ORDER BY category_observations DESC
LIMIT 20;