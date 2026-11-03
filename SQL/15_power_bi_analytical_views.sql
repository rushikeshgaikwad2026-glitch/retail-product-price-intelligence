
-- ============================================================
-- PROJECT 1: RETAIL PRODUCT & PRICE INTELLIGENCE
-- FILE: 15_power_bi_analytical_views.sql
--
-- VIEW 1: PRODUCT PRICE PERFORMANCE
-- Purpose:
-- Summarise product-level price performance separately
-- for each currency.
-- ============================================================

CREATE OR REPLACE VIEW vw_product_price_performance AS

SELECT

    dp.product_id,
    dp.product_code,

    -- Product name: use the most frequently observed
    -- nonblank name for this product.
    (
        SELECT dname.product_name
        FROM dim_product_names dname
        WHERE dname.product_id = dp.product_id
        ORDER BY dname.product_name
        LIMIT 1
    ) AS product_name,

    cur.currency_code,

    COUNT(*) AS observation_count,

    COUNT(DISTINCT f.location_key) AS location_count,

    COUNT(DISTINCT f.date_key) AS active_days,

    ROUND(AVG(f.price), 2) AS average_price,

    ROUND(MIN(f.price), 2) AS minimum_price,

    ROUND(MAX(f.price), 2) AS maximum_price,

    ROUND(STDDEV_POP(f.price), 2) AS price_std_deviation,

    SUM(
        CASE
            WHEN f.price_is_discounted = 1 THEN 1
            ELSE 0
        END
    ) AS discounted_observations,

    ROUND(
        SUM(
            CASE
                WHEN f.price_is_discounted = 1 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS discount_rate_pct

FROM fact_price_observations f

INNER JOIN dim_products dp
    ON f.product_id = dp.product_id

INNER JOIN dim_currency cur
    ON f.currency_key = cur.currency_key

WHERE f.zero_price_flag = 0
  AND cur.is_unknown = 0

GROUP BY
    dp.product_id,
    dp.product_code,
    cur.currency_code;


SELECT *
FROM vw_product_price_performance
LIMIT 10;

SELECT COUNT(*) AS total_view_records
FROM vw_product_price_performance;




-- ============================================================
-- VIEW 2: CATEGORY PRICE PERFORMANCE
-- Purpose:
-- Category-level price analysis for Power BI.
-- Median is calculated using ordered observations.
-- ============================================================

CREATE OR REPLACE VIEW vw_category_price_performance AS

WITH ranked_prices AS (

    SELECT
        dc.category_tag,
        cur.currency_code,
        fc.price_per,
        fc.price,
        fc.location_key,
        fc.date_key,

        ROW_NUMBER() OVER (
            PARTITION BY
                dc.category_key,
                fc.currency_key,
                fc.price_per
            ORDER BY fc.price
        ) AS price_rank,

        COUNT(*) OVER (
            PARTITION BY
                dc.category_key,
                fc.currency_key,
                fc.price_per
        ) AS observation_count

    FROM fact_category_observations fc

    INNER JOIN dim_categories dc
        ON fc.category_key = dc.category_key

    INNER JOIN dim_currency cur
        ON fc.currency_key = cur.currency_key

    WHERE fc.price > 0
      AND cur.is_unknown = 0

)

SELECT
    category_tag,
    currency_code,
    price_per,

    COUNT(*) AS total_observations,

    COUNT(DISTINCT location_key) AS location_count,

    COUNT(DISTINCT date_key) AS active_days,

    ROUND(AVG(price), 2) AS average_price,

    ROUND(
        MAX(
            CASE
                WHEN price_rank = FLOOR((observation_count + 1) / 2)
                THEN price
            END
        ),
        2
    ) AS median_price_lower,

    ROUND(
        MAX(
            CASE
                WHEN price_rank = FLOOR((observation_count + 2) / 2)
                THEN price
            END
        ),
        2
    ) AS median_price_upper,

    ROUND(MIN(price), 2) AS minimum_price,

    ROUND(MAX(price), 2) AS maximum_price,

    ROUND(STDDEV_POP(price), 2) AS price_std_deviation

FROM ranked_prices

GROUP BY
    category_tag,
    currency_code,
    price_per,
    observation_count;


SELECT *
FROM vw_category_price_performance
ORDER BY total_observations DESC
LIMIT 15;

SELECT COUNT(*) AS total_category_groups
FROM vw_category_price_performance;



DESCRIBE dim_locations;

SELECT *
FROM dim_locations
LIMIT 3;


-- ============================================================
-- VIEW 3: GEOGRAPHIC PRICE BENCHMARK
-- Uses actual dim_locations column names.
-- ============================================================

CREATE OR REPLACE VIEW vw_geographic_price_benchmark AS

WITH ranked_prices AS (

    SELECT
        dc.category_tag,
        dl.country,
        cur.currency_code,
        fc.price_per,
        fc.price,
        fc.location_key,
        fc.date_key,

        ROW_NUMBER() OVER (
            PARTITION BY
                dc.category_key,
                dl.country,
                fc.currency_key,
                fc.price_per
            ORDER BY fc.price
        ) AS price_rank,

        COUNT(*) OVER (
            PARTITION BY
                dc.category_key,
                dl.country,
                fc.currency_key,
                fc.price_per
        ) AS observation_count

    FROM fact_category_observations fc

    INNER JOIN dim_categories dc
        ON fc.category_key = dc.category_key

    INNER JOIN dim_locations dl
        ON fc.location_key = dl.location_key

    INNER JOIN dim_currency cur
        ON fc.currency_key = cur.currency_key

    WHERE fc.price > 0
      AND cur.is_unknown = 0
      AND dl.country IS NOT NULL
      AND TRIM(dl.country) <> ''

)

SELECT
    category_tag,
    country,
    currency_code,
    price_per,

    COUNT(*) AS total_observations,

    COUNT(DISTINCT location_key) AS location_count,

    COUNT(DISTINCT date_key) AS active_days,

    ROUND(AVG(price), 2) AS average_price,

    ROUND(
        (
            MAX(
                CASE
                    WHEN price_rank = FLOOR((observation_count + 1) / 2)
                    THEN price
                END
            )
            +
            MAX(
                CASE
                    WHEN price_rank = FLOOR((observation_count + 2) / 2)
                    THEN price
                END
            )
        ) / 2,
        2
    ) AS median_price,

    ROUND(MIN(price), 2) AS minimum_price,

    ROUND(MAX(price), 2) AS maximum_price,

    ROUND(STDDEV_POP(price), 2) AS price_std_deviation

FROM ranked_prices

GROUP BY
    category_tag,
    country,
    currency_code,
    price_per,
    observation_count;


SELECT *
FROM vw_geographic_price_benchmark
WHERE category_tag = 'en:apples'
ORDER BY total_observations DESC;

SELECT COUNT(*) AS total_geographic_groups
FROM vw_geographic_price_benchmark;


SELECT
    country,
    currency_code,
    SUM(total_observations) AS observations,
    COUNT(*) AS category_groups
FROM vw_geographic_price_benchmark
GROUP BY country, currency_code
ORDER BY observations DESC
LIMIT 15;


DESCRIBE dim_date;

SELECT *
FROM dim_date
LIMIT 5;


-- ============================================================
-- VIEW 4: MONTHLY PRICE TRENDS
-- Uses actual dim_date column names.
-- ============================================================

CREATE OR REPLACE VIEW vw_monthly_price_trends AS

WITH monthly_ranked_prices AS (

    SELECT
        dc.category_tag,
        cur.currency_code,
        fc.price_per,

        dd.year_number AS observation_year,
        dd.month_number AS observation_month,

        fc.price,
        fc.location_key,

        ROW_NUMBER() OVER (
            PARTITION BY
                dc.category_key,
                fc.currency_key,
                fc.price_per,
                dd.year_number,
                dd.month_number
            ORDER BY fc.price
        ) AS price_rank,

        COUNT(*) OVER (
            PARTITION BY
                dc.category_key,
                fc.currency_key,
                fc.price_per,
                dd.year_number,
                dd.month_number
        ) AS observation_count

    FROM fact_category_observations fc

    INNER JOIN dim_categories dc
        ON fc.category_key = dc.category_key

    INNER JOIN dim_currency cur
        ON fc.currency_key = cur.currency_key

    INNER JOIN dim_date dd
        ON fc.date_key = dd.date_key

    WHERE fc.price > 0
      AND cur.is_unknown = 0

)

SELECT
    category_tag,
    currency_code,
    price_per,

    observation_year,
    observation_month,

    COUNT(*) AS total_observations,

    COUNT(DISTINCT location_key) AS location_count,

    ROUND(AVG(price), 2) AS average_price,

    ROUND(
        (
            MAX(
                CASE
                    WHEN price_rank = FLOOR((observation_count + 1) / 2)
                    THEN price
                END
            )
            +
            MAX(
                CASE
                    WHEN price_rank = FLOOR((observation_count + 2) / 2)
                    THEN price
                END
            )
        ) / 2,
        2
    ) AS median_price,

    ROUND(MIN(price), 2) AS minimum_price,

    ROUND(MAX(price), 2) AS maximum_price,

    ROUND(STDDEV_POP(price), 2) AS price_std_deviation

FROM monthly_ranked_prices

GROUP BY
    category_tag,
    currency_code,
    price_per,
    observation_year,
    observation_month;



SELECT *
FROM vw_monthly_price_trends
WHERE category_tag = 'en:apples'
  AND currency_code = 'EUR'
  AND price_per = 'KILOGRAM'
ORDER BY observation_year, observation_month;


SELECT COUNT(*) AS total_monthly_groups
FROM vw_monthly_price_trends;


SELECT
    observation_year,
    observation_month,
    SUM(total_observations) AS total_observations,
    COUNT(*) AS category_groups
FROM vw_monthly_price_trends
GROUP BY
    observation_year,
    observation_month
ORDER BY
    observation_year,
    observation_month;




-- ============================================================
-- VIEW 5: PRICE OUTLIER INTELLIGENCE
-- Purpose:
-- Identify unusually high observed prices using IQR.
--
-- Grouping:
-- Category + Currency + Measurement Basis
--
-- Minimum sample size: 10 observations
-- Outlier rule: Price > Q3 + (1.5 * IQR)
-- ============================================================

CREATE OR REPLACE VIEW vw_category_price_outlier_intelligence AS

WITH ranked_prices AS (

    SELECT
        dc.category_key,
        dc.category_tag,
        cur.currency_code,
        fc.price_per,
        fc.price,

        ROW_NUMBER() OVER (
            PARTITION BY
                fc.category_key,
                fc.currency_key,
                fc.price_per
            ORDER BY fc.price
        ) AS price_rank,

        COUNT(*) OVER (
            PARTITION BY
                fc.category_key,
                fc.currency_key,
                fc.price_per
        ) AS observation_count

    FROM fact_category_observations fc

    INNER JOIN dim_categories dc
        ON fc.category_key = dc.category_key

    INNER JOIN dim_currency cur
        ON fc.currency_key = cur.currency_key

    WHERE fc.price > 0
      AND cur.is_unknown = 0

),

quartile_positions AS (

    SELECT
        category_key,
        category_tag,
        currency_code,
        price_per,
        price,
        price_rank,
        observation_count,

        FLOOR((observation_count + 3) / 4) AS q1_position,

        FLOOR((3 * observation_count + 1) / 4) AS q3_position

    FROM ranked_prices

),

category_quartiles AS (

    SELECT
        category_key,
        category_tag,
        currency_code,
        price_per,

        MAX(observation_count) AS total_observations,

        MAX(
            CASE
                WHEN price_rank = q1_position
                THEN price
            END
        ) AS q1_price,

        MAX(
            CASE
                WHEN price_rank = q3_position
                THEN price
            END
        ) AS q3_price,

        MAX(price) AS maximum_price

    FROM quartile_positions

    GROUP BY
        category_key,
        category_tag,
        currency_code,
        price_per

    HAVING MAX(observation_count) >= 10

),

outlier_counts AS (

    SELECT
        q.category_key,
        q.category_tag,
        q.currency_code,
        q.price_per,

        COUNT(*) AS total_observations,

        SUM(
            CASE
                WHEN rp.price >
                    q.q3_price + (1.5 * (q.q3_price - q.q1_price))
                THEN 1
                ELSE 0
            END
        ) AS high_outlier_count,

        COUNT(DISTINCT rp.price) AS distinct_price_values,

        q.q1_price,
        q.q3_price,
        q.maximum_price

    FROM category_quartiles q

    INNER JOIN ranked_prices rp
        ON q.category_key = rp.category_key
       AND q.currency_code = rp.currency_code
       AND q.price_per = rp.price_per

    GROUP BY
        q.category_key,
        q.category_tag,
        q.currency_code,
        q.price_per,
        q.q1_price,
        q.q3_price,
        q.maximum_price

)

SELECT
    category_tag,
    currency_code,
    price_per,

    total_observations,

    ROUND(q1_price, 2) AS q1_price,

    ROUND(q3_price, 2) AS q3_price,

    ROUND(q3_price - q1_price, 2) AS iqr,

    ROUND(
        q3_price + (1.5 * (q3_price - q1_price)),
        2
    ) AS upper_outlier_limit,

    maximum_price,

    high_outlier_count,

    ROUND(
        high_outlier_count * 100.0 / total_observations,
        2
    ) AS high_outlier_rate_pct

FROM outlier_counts;


SELECT *
FROM vw_category_price_outlier_intelligence
ORDER BY high_outlier_count DESC
LIMIT 20;


SELECT COUNT(*) AS total_outlier_groups
FROM vw_category_price_outlier_intelligence;


SELECT *
FROM vw_category_price_outlier_intelligence
WHERE category_tag = 'en:apples'
  AND currency_code = 'EUR'
  AND price_per = 'KILOGRAM';




-- ============================================================
-- PROJECT 1: FINAL POWER BI SCHEMA INSPECTION
-- ============================================================

DESCRIBE vw_product_price_performance;

DESCRIBE vw_category_price_performance;

DESCRIBE vw_geographic_price_benchmark;

DESCRIBE vw_monthly_price_trends;

DESCRIBE vw_category_price_outlier_intelligence;



-- ============================================================
-- FINAL ANALYTICAL VIEW VALIDATION
-- ============================================================

SELECT 'Product Performance' AS view_name,
       COUNT(*) AS total_records
FROM vw_product_price_performance

UNION ALL

SELECT 'Category Performance',
       COUNT(*)
FROM vw_category_price_performance

UNION ALL

SELECT 'Geographic Benchmark',
       COUNT(*)
FROM vw_geographic_price_benchmark

UNION ALL

SELECT 'Monthly Price Trends',
       COUNT(*)
FROM vw_monthly_price_trends

UNION ALL

SELECT 'Price Outlier Intelligence',
       COUNT(*)
FROM vw_category_price_outlier_intelligence;



DESCRIBE vw_product_price_performance;

DESCRIBE vw_category_price_performance;

DESCRIBE vw_geographic_price_benchmark;

DESCRIBE vw_monthly_price_trends;




SELECT dc.category_tag
FROM dim_categories dc
LEFT JOIN (
    SELECT DISTINCT category_tag
    FROM vw_category_price_performance
) vp
    ON dc.category_tag = vp.category_tag
WHERE vp.category_tag IS NULL;