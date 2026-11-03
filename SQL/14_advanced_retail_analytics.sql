
-- ============================================================
-- PROJECT 01: RETAIL PRODUCT & PRICE INTELLIGENCE
-- FILE: 14_advanced_retail_analytics.sql
-- MODULE 1: CATEGORY PRICE BENCHMARKING
-- QUERY 1: Category Price Performance
-- ============================================================

USE retail_price_intelligence;

-- Business objective:
-- Compare category-level prices within the same currency
-- and measurement basis.
--
-- Important:
-- 1. Do not compare different currencies.
-- 2. Do not mix KILOGRAM and UNIT prices.
-- 3. Exclude zero-price observations from price statistics.
-- 4. Keep observation counts visible to assess reliability.

SELECT
    dc.category_tag,
    fc.currency_key,
    cur.currency_code,
    fc.price_per,

    COUNT(*) AS observation_count,

    COUNT(DISTINCT fc.location_key) AS location_count,

    COUNT(DISTINCT fc.date_key) AS active_dates,

    ROUND(AVG(fc.price), 2) AS average_price,

    ROUND(MIN(fc.price), 2) AS minimum_price,

    ROUND(MAX(fc.price), 2) AS maximum_price,

    ROUND(STDDEV_POP(fc.price), 2) AS price_std_deviation

FROM fact_category_observations fc

INNER JOIN dim_categories dc
    ON fc.category_key = dc.category_key

INNER JOIN dim_currency cur
    ON fc.currency_key = cur.currency_key

WHERE fc.price > 0
  AND cur.is_unknown = 0

GROUP BY
    dc.category_tag,
    fc.currency_key,
    cur.currency_code,
    fc.price_per

HAVING COUNT(*) >= 5

ORDER BY
    cur.currency_code,
    fc.price_per,
    average_price DESC;



-- ============================================================
-- MODULE 1: CATEGORY PRICE BENCHMARKING
-- QUERY 2: Relative Price Variation (Coefficient of Variation)
-- ============================================================

SELECT
    dc.category_tag,
    cur.currency_code,
    fc.price_per,

    COUNT(*) AS observation_count,

    COUNT(DISTINCT fc.location_key) AS location_count,

    ROUND(AVG(fc.price), 2) AS average_price,

    ROUND(STDDEV_POP(fc.price), 2) AS price_std_deviation,

    ROUND(
        (STDDEV_POP(fc.price) / NULLIF(AVG(fc.price), 0)) * 100,
        2
    ) AS coefficient_of_variation_pct

FROM fact_category_observations fc

INNER JOIN dim_categories dc
    ON fc.category_key = dc.category_key

INNER JOIN dim_currency cur
    ON fc.currency_key = cur.currency_key

WHERE fc.price > 0
  AND cur.is_unknown = 0

GROUP BY
    dc.category_tag,
    cur.currency_code,
    fc.price_per

HAVING COUNT(*) >= 10
   AND COUNT(DISTINCT fc.location_key) >= 3

ORDER BY
    coefficient_of_variation_pct DESC;



-- ============================================================
-- MODULE 1: CATEGORY PRICE BENCHMARKING
-- QUERY 3: Investigate Turmeric Price Variation
-- ============================================================

SELECT
    observation_id,
    category_tag,
    location_key,
    currency_key,
    price,
    price_per,
    observation_datetime,
    zero_price_flag,
    source

FROM fact_category_observations

WHERE category_tag = 'en:turmeric'
  AND currency_key = (
      SELECT currency_key
      FROM dim_currency
      WHERE currency_code = 'EUR'
  )
  AND price_per = 'KILOGRAM'
  AND price > 0

ORDER BY price DESC;




-- ============================================================
-- QUERY 4: Turmeric Outlier Impact Analysis
-- Sensitivity analysis: original vs excluding top 2 prices
-- ============================================================

WITH turmeric_prices AS (
    SELECT
        observation_id,
        price,

        ROW_NUMBER() OVER (
            ORDER BY price DESC, observation_id
        ) AS price_rank

    FROM fact_category_observations

    WHERE category_tag = 'en:turmeric'
      AND currency_key = (
          SELECT currency_key
          FROM dim_currency
          WHERE currency_code = 'EUR'
      )
      AND price_per = 'KILOGRAM'
      AND price > 0
)

SELECT
    'All observations' AS analysis_group,
    COUNT(*) AS observation_count,
    ROUND(AVG(price), 2) AS average_price,
    ROUND(STDDEV_POP(price), 2) AS std_deviation,
    ROUND(MIN(price), 2) AS minimum_price,
    ROUND(MAX(price), 2) AS maximum_price

FROM turmeric_prices

UNION ALL

SELECT
    'Excluding top 2 observations',
    COUNT(*),
    ROUND(AVG(price), 2),
    ROUND(STDDEV_POP(price), 2),
    ROUND(MIN(price), 2),
    ROUND(MAX(price), 2)

FROM turmeric_prices
WHERE price_rank > 2;



-- ============================================================
-- MODULE 2: GEOGRAPHIC PRICE INTELLIGENCE
-- QUERY 5: Category Price Variation Across Countries
-- ============================================================

SELECT
    dc.category_tag,
    cur.currency_code,
    fc.price_per,

    dl.country,

    COUNT(*) AS observation_count,

    COUNT(DISTINCT fc.location_key) AS location_count,

    ROUND(AVG(fc.price), 2) AS average_price,

    ROUND(MIN(fc.price), 2) AS minimum_price,

    ROUND(MAX(fc.price), 2) AS maximum_price,

    ROUND(STDDEV_POP(fc.price), 2) AS price_std_deviation

FROM fact_category_observations fc

INNER JOIN dim_categories dc
    ON fc.category_key = dc.category_key

INNER JOIN dim_currency cur
    ON fc.currency_key = cur.currency_key

INNER JOIN dim_locations dl
    ON fc.location_key = dl.location_key

WHERE fc.price > 0
  AND cur.is_unknown = 0
  AND dl.country IS NOT NULL
  AND TRIM(dl.country) <> ''

GROUP BY
    dc.category_tag,
    cur.currency_code,
    fc.price_per,
    dl.country

HAVING COUNT(*) >= 5
   AND COUNT(DISTINCT fc.location_key) >= 3

ORDER BY
    dc.category_tag,
    cur.currency_code,
    fc.price_per,
    average_price DESC;


-- ============================================================
-- MODULE 2: GEOGRAPHIC PRICE INTELLIGENCE
-- QUERY 6: EUR/KG Apple Price Comparison Across Countries
-- ============================================================

SELECT
    dl.country,

    COUNT(*) AS observation_count,

    COUNT(DISTINCT fc.location_key) AS location_count,

    COUNT(DISTINCT fc.date_key) AS active_dates,

    ROUND(AVG(fc.price), 2) AS average_price,

    ROUND(
        MIN(fc.price),
        2
    ) AS minimum_price,

    ROUND(
        MAX(fc.price),
        2
    ) AS maximum_price,

    ROUND(
        STDDEV_POP(fc.price),
        2
    ) AS price_std_deviation

FROM fact_category_observations fc

INNER JOIN dim_categories dc
    ON fc.category_key = dc.category_key

INNER JOIN dim_currency cur
    ON fc.currency_key = cur.currency_key

INNER JOIN dim_locations dl
    ON fc.location_key = dl.location_key

WHERE dc.category_tag = 'en:apples'
  AND cur.currency_code = 'EUR'
  AND fc.price_per = 'KILOGRAM'
  AND fc.price > 0
  AND dl.country IS NOT NULL

GROUP BY
    dl.country

HAVING COUNT(*) >= 5
   AND COUNT(DISTINCT fc.location_key) >= 3

ORDER BY
    average_price DESC;


-- ============================================================
-- QUERY 7: Investigate French Apple Price Distribution
-- ============================================================

SELECT
    fc.observation_id,
    fc.location_key,
    dl.city,
    fc.price,
    fc.observation_datetime,
    fc.source

FROM fact_category_observations fc

INNER JOIN dim_categories dc
    ON fc.category_key = dc.category_key

INNER JOIN dim_currency cur
    ON fc.currency_key = cur.currency_key

INNER JOIN dim_locations dl
    ON fc.location_key = dl.location_key

WHERE dc.category_tag = 'en:apples'
  AND cur.currency_code = 'EUR'
  AND fc.price_per = 'KILOGRAM'
  AND fc.price > 0
  AND dl.country = 'France'

ORDER BY fc.price DESC

LIMIT 15;



-- ============================================================
-- QUERY 8: Country-wise Apple Price Comparison
-- Average vs Median
-- EUR / KILOGRAM
-- ============================================================

WITH country_prices AS (

    SELECT
        dl.country,
        fc.price,

        ROW_NUMBER() OVER (
            PARTITION BY dl.country
            ORDER BY fc.price
        ) AS price_rank,

        COUNT(*) OVER (
            PARTITION BY dl.country
        ) AS total_observations

    FROM fact_category_observations fc

    INNER JOIN dim_categories dc
        ON fc.category_key = dc.category_key

    INNER JOIN dim_currency cur
        ON fc.currency_key = cur.currency_key

    INNER JOIN dim_locations dl
        ON fc.location_key = dl.location_key

    WHERE dc.category_tag = 'en:apples'
      AND cur.currency_code = 'EUR'
      AND fc.price_per = 'KILOGRAM'
      AND fc.price > 0
      AND dl.country IS NOT NULL
      AND TRIM(dl.country) <> ''

),

country_summary AS (

    SELECT
        country,

        COUNT(*) AS observation_count,

        ROUND(AVG(price), 2) AS average_price,

        ROUND(
            AVG(
                CASE
                    WHEN price_rank IN (
                        FLOOR((total_observations + 1) / 2),
                        FLOOR((total_observations + 2) / 2)
                    )
                    THEN price
                END
            ),
            2
        ) AS median_price,

        ROUND(MIN(price), 2) AS minimum_price,

        ROUND(MAX(price), 2) AS maximum_price

    FROM country_prices

    GROUP BY country

)

SELECT
    country,
    observation_count,
    average_price,
    median_price,
    minimum_price,
    maximum_price

FROM country_summary

ORDER BY average_price DESC;



-- ============================================================
-- QUERY 9: Country-wise Median Price Difference
-- Reference country: France
-- EUR / KILOGRAM
-- ============================================================

WITH country_prices AS (

    SELECT
        dl.country,
        fc.price,

        ROW_NUMBER() OVER (
            PARTITION BY dl.country
            ORDER BY fc.price
        ) AS price_rank,

        COUNT(*) OVER (
            PARTITION BY dl.country
        ) AS total_observations

    FROM fact_category_observations fc

    INNER JOIN dim_categories dc
        ON fc.category_key = dc.category_key

    INNER JOIN dim_currency cur
        ON fc.currency_key = cur.currency_key

    INNER JOIN dim_locations dl
        ON fc.location_key = dl.location_key

    WHERE dc.category_tag = 'en:apples'
      AND cur.currency_code = 'EUR'
      AND fc.price_per = 'KILOGRAM'
      AND fc.price > 0
      AND dl.country IS NOT NULL
      AND TRIM(dl.country) <> ''

),

country_medians AS (

    SELECT
        country,
        COUNT(*) AS observation_count,

        AVG(
            CASE
                WHEN price_rank IN (
                    FLOOR((total_observations + 1) / 2),
                    FLOOR((total_observations + 2) / 2)
                )
                THEN price
            END
        ) AS median_price

    FROM country_prices

    GROUP BY country

),

france_benchmark AS (

    SELECT median_price AS france_median
    FROM country_medians
    WHERE country = 'France'

)

SELECT
    cm.country,
    cm.observation_count,

    ROUND(cm.median_price, 2) AS country_median_price,

    ROUND(fb.france_median, 2) AS france_median_price,

    ROUND(
        (
            (cm.median_price - fb.france_median)
            / NULLIF(fb.france_median, 0)
        ) * 100,
        2
    ) AS difference_from_france_pct

FROM country_medians cm

CROSS JOIN france_benchmark fb

WHERE cm.observation_count >= 5

ORDER BY difference_from_france_pct DESC;



-- ============================================================
-- QUERY 10: French Apple Price Benchmark by Location
-- EUR / KILOGRAM
-- ============================================================

SELECT
    dl.city,
    dl.location_id,

    COUNT(*) AS observation_count,

    COUNT(DISTINCT fc.date_key) AS active_dates,

    ROUND(AVG(fc.price), 2) AS average_price,

    ROUND(MIN(fc.price), 2) AS minimum_price,

    ROUND(MAX(fc.price), 2) AS maximum_price

FROM fact_category_observations fc

INNER JOIN dim_categories dc
    ON fc.category_key = dc.category_key

INNER JOIN dim_currency cur
    ON fc.currency_key = cur.currency_key

INNER JOIN dim_locations dl
    ON fc.location_key = dl.location_key

WHERE dc.category_tag = 'en:apples'
  AND cur.currency_code = 'EUR'
  AND fc.price_per = 'KILOGRAM'
  AND fc.price > 0
  AND dl.country = 'France'

GROUP BY
    dl.city,
    dl.location_id

HAVING COUNT(*) >= 2

ORDER BY average_price DESC

LIMIT 15;



-- ============================================================
-- QUERY 11: Investigate Apple Prices in Veynes
-- ============================================================

SELECT
    fc.observation_id,
    dl.location_id,
    dl.city,
    fc.price,
    fc.observation_datetime,
    fc.source,
    fc.zero_price_flag,
    fc.etl_batch_id

FROM fact_category_observations fc

INNER JOIN dim_categories dc
    ON fc.category_key = dc.category_key

INNER JOIN dim_currency cur
    ON fc.currency_key = cur.currency_key

INNER JOIN dim_locations dl
    ON fc.location_key = dl.location_key

WHERE dc.category_tag = 'en:apples'
  AND cur.currency_code = 'EUR'
  AND fc.price_per = 'KILOGRAM'
  AND fc.price > 0
  AND dl.location_id = 127

ORDER BY fc.observation_datetime;



-- ============================================================
-- QUERY 12: Detailed Source Investigation
-- Veynes Apple Price Observations
-- ============================================================

SELECT
    id AS observation_id,
    type,
    category_tag,
    product_name,
    price,
    currency,
    price_per,
    date,

    proof_id,
    proof_type,
    proof_date,
    proof_currency,
    proof_receipt_price_count,
    proof_receipt_price_total,

    receipt_quantity,
    source,
    proof_source,
    created,
    updated

FROM stg_open_prices

WHERE id IN (4301, 59876, 62870)

ORDER BY date, id;



-- ============================================================
-- QUERY 13: Identify Potentially Unusual Apple Prices
-- France | EUR | KILOGRAM
-- ============================================================

WITH price_statistics AS (

    SELECT
        AVG(fc.price) AS average_price,
        STDDEV_POP(fc.price) AS standard_deviation

    FROM fact_category_observations fc

    INNER JOIN dim_categories dc
        ON fc.category_key = dc.category_key

    INNER JOIN dim_currency cur
        ON fc.currency_key = cur.currency_key

    INNER JOIN dim_locations dl
        ON fc.location_key = dl.location_key

    WHERE dc.category_tag = 'en:apples'
      AND cur.currency_code = 'EUR'
      AND fc.price_per = 'KILOGRAM'
      AND fc.price > 0
      AND dl.country = 'France'

)

SELECT
    fc.observation_id,
    dl.city,
    dl.location_id,
    fc.price,
    fc.observation_datetime,

    ROUND(ps.average_price, 2) AS overall_average,

    ROUND(ps.standard_deviation, 2) AS overall_std_dev,

    ROUND(
        (fc.price - ps.average_price)
        / NULLIF(ps.standard_deviation, 0),
        2
    ) AS z_score

FROM fact_category_observations fc

INNER JOIN dim_categories dc
    ON fc.category_key = dc.category_key

INNER JOIN dim_currency cur
    ON fc.currency_key = cur.currency_key

INNER JOIN dim_locations dl
    ON fc.location_key = dl.location_key

CROSS JOIN price_statistics ps

WHERE dc.category_tag = 'en:apples'
  AND cur.currency_code = 'EUR'
  AND fc.price_per = 'KILOGRAM'
  AND fc.price > 0
  AND dl.country = 'France'

  AND fc.price >
      ps.average_price + (2 * ps.standard_deviation)

ORDER BY z_score DESC;



-- ============================================================
-- QUERY 14: Investigate Other High Apple Price Observations
-- Avèze and Grenoble
-- ============================================================

SELECT
    s.id AS observation_id,
    s.category_tag,
    s.price,
    s.currency,
    s.price_per,
    s.date,

    s.proof_id,
    s.proof_type,
    s.proof_date,
    s.proof_currency,
    s.receipt_quantity,

    s.source,
    s.proof_source,

    s.created,
    s.updated,

    dl.city,
    dl.location_id

FROM stg_open_prices s

INNER JOIN dim_locations dl
    ON s.location_id = dl.location_id

WHERE s.id IN (95330, 91962)

ORDER BY s.id;



-- ============================================================
-- QUERY 15: IQR-Based Outlier Detection
-- France | Apples | EUR | KILOGRAM
-- ============================================================

WITH ranked_prices AS (

    SELECT
        fc.observation_id,
        dl.city,
        dl.location_id,
        fc.price,

        ROW_NUMBER() OVER (
            ORDER BY fc.price
        ) AS price_rank,

        COUNT(*) OVER () AS total_observations

    FROM fact_category_observations fc

    INNER JOIN dim_categories dc
        ON fc.category_key = dc.category_key

    INNER JOIN dim_currency cur
        ON fc.currency_key = cur.currency_key

    INNER JOIN dim_locations dl
        ON fc.location_key = dl.location_key

    WHERE dc.category_tag = 'en:apples'
      AND cur.currency_code = 'EUR'
      AND fc.price_per = 'KILOGRAM'
      AND fc.price > 0
      AND dl.country = 'France'

),

quartiles AS (

    SELECT
        MAX(
            CASE
                WHEN price_rank = CEIL(total_observations * 0.25)
                THEN price
            END
        ) AS q1,

        MAX(
            CASE
                WHEN price_rank = CEIL(total_observations * 0.75)
                THEN price
            END
        ) AS q3,

        COUNT(*) AS observation_count

    FROM ranked_prices

),

iqr_bounds AS (

    SELECT
        q1,
        q3,
        q3 - q1 AS iqr,

        q1 - (1.5 * (q3 - q1)) AS lower_bound,

        q3 + (1.5 * (q3 - q1)) AS upper_bound,

        observation_count

    FROM quartiles

)

SELECT
    rp.observation_id,
    rp.city,
    rp.location_id,
    rp.price,

    ib.q1,
    ib.q3,
    ib.iqr,
    ib.lower_bound,
    ib.upper_bound,

    CASE
        WHEN rp.price > ib.upper_bound
            THEN 'HIGH OUTLIER'

        WHEN rp.price < ib.lower_bound
            THEN 'LOW OUTLIER'

        ELSE 'NORMAL'
    END AS outlier_status

FROM ranked_prices rp

CROSS JOIN iqr_bounds ib

WHERE rp.price > ib.upper_bound
   OR rp.price < ib.lower_bound

ORDER BY rp.price DESC;



-- ============================================================
-- QUERY 16: Investigate Paris High-Price Observations
-- ============================================================

SELECT
    id AS observation_id,
    category_tag,
    price,
    currency,
    price_per,
    date,

    proof_id,
    proof_type,
    proof_date,
    proof_currency,
    receipt_quantity,

    source,
    proof_source,

    created,
    updated

FROM stg_open_prices

WHERE id IN (43608, 94095)

ORDER BY id;



-- ============================================================
-- QUERY 17: Reusable Category-Level IQR Outlier Detection
-- ============================================================

WITH ranked_prices AS (

    SELECT
        dc.category_tag,
        cur.currency_code,
        fc.price_per,
        fc.observation_id,
        fc.price,

        ROW_NUMBER() OVER (
            PARTITION BY
                dc.category_tag,
                cur.currency_code,
                fc.price_per
            ORDER BY fc.price
        ) AS price_rank,

        COUNT(*) OVER (
            PARTITION BY
                dc.category_tag,
                cur.currency_code,
                fc.price_per
        ) AS total_observations

    FROM fact_category_observations fc

    INNER JOIN dim_categories dc
        ON fc.category_key = dc.category_key

    INNER JOIN dim_currency cur
        ON fc.currency_key = cur.currency_key

    WHERE fc.price > 0
      AND cur.is_unknown = 0

),

quartiles AS (

    SELECT
        category_tag,
        currency_code,
        price_per,

        COUNT(*) AS observation_count,

        MAX(
            CASE
                WHEN price_rank = CEIL(total_observations * 0.25)
                THEN price
            END
        ) AS q1,

        MAX(
            CASE
                WHEN price_rank = CEIL(total_observations * 0.75)
                THEN price
            END
        ) AS q3

    FROM ranked_prices

    GROUP BY
        category_tag,
        currency_code,
        price_per

    HAVING COUNT(*) >= 10

),

iqr_bounds AS (

    SELECT
        category_tag,
        currency_code,
        price_per,
        observation_count,
        q1,
        q3,

        q3 - q1 AS iqr,

        q3 + 1.5 * (q3 - q1) AS upper_bound

    FROM quartiles

)

SELECT
    rp.category_tag,
    rp.currency_code,
    rp.price_per,

    ib.observation_count,

    COUNT(*) AS high_outlier_count,

    ROUND(ib.q1, 2) AS q1,
    ROUND(ib.q3, 2) AS q3,
    ROUND(ib.iqr, 2) AS iqr,

    ROUND(ib.upper_bound, 2) AS upper_bound,

    ROUND(MAX(rp.price), 2) AS highest_outlier_price

FROM ranked_prices rp

INNER JOIN iqr_bounds ib
    ON rp.category_tag = ib.category_tag
   AND rp.currency_code = ib.currency_code
   AND rp.price_per = ib.price_per

WHERE rp.price > ib.upper_bound

GROUP BY
    rp.category_tag,
    rp.currency_code,
    rp.price_per,
    ib.observation_count,
    ib.q1,
    ib.q3,
    ib.iqr,
    ib.upper_bound

ORDER BY high_outlier_count DESC;




-- ============================================================
-- QUERY 18: Category-Level IQR Outlier Rate
-- ============================================================

WITH ranked_prices AS (

    SELECT
        dc.category_tag,
        cur.currency_code,
        fc.price_per,
        fc.observation_id,
        fc.price,

        ROW_NUMBER() OVER (
            PARTITION BY
                dc.category_tag,
                cur.currency_code,
                fc.price_per
            ORDER BY fc.price
        ) AS price_rank,

        COUNT(*) OVER (
            PARTITION BY
                dc.category_tag,
                cur.currency_code,
                fc.price_per
        ) AS total_observations

    FROM fact_category_observations fc

    INNER JOIN dim_categories dc
        ON fc.category_key = dc.category_key

    INNER JOIN dim_currency cur
        ON fc.currency_key = cur.currency_key

    WHERE fc.price > 0
      AND cur.is_unknown = 0

),

quartiles AS (

    SELECT
        category_tag,
        currency_code,
        price_per,

        COUNT(*) AS observation_count,

        MAX(
            CASE
                WHEN price_rank = CEIL(total_observations * 0.25)
                THEN price
            END
        ) AS q1,

        MAX(
            CASE
                WHEN price_rank = CEIL(total_observations * 0.75)
                THEN price
            END
        ) AS q3

    FROM ranked_prices

    GROUP BY
        category_tag,
        currency_code,
        price_per

    HAVING COUNT(*) >= 10

),

classified_prices AS (

    SELECT
        rp.category_tag,
        rp.currency_code,
        rp.price_per,
        rp.observation_id,
        rp.price,
        q.observation_count,
        q.q1,
        q.q3,
        q.q3 - q.q1 AS iqr,

        CASE
            WHEN q.q3 - q.q1 = 0 THEN 'ZERO IQR'
            WHEN rp.price > q.q3 + 1.5 * (q.q3 - q.q1)
                THEN 'HIGH OUTLIER'
            ELSE 'NORMAL'
        END AS price_status

    FROM ranked_prices rp

    INNER JOIN quartiles q
        ON rp.category_tag = q.category_tag
       AND rp.currency_code = q.currency_code
       AND rp.price_per = q.price_per

)

SELECT
    category_tag,
    currency_code,
    price_per,

    MAX(observation_count) AS observation_count,

    COUNT(
        CASE WHEN price_status = 'HIGH OUTLIER' THEN 1 END
    ) AS high_outlier_count,

    ROUND(
        COUNT(
            CASE WHEN price_status = 'HIGH OUTLIER' THEN 1 END
        ) * 100.0 / MAX(observation_count),
        2
    ) AS high_outlier_rate_pct,

    ROUND(MAX(q1), 2) AS q1,
    ROUND(MAX(q3), 2) AS q3,
    ROUND(MAX(iqr), 2) AS iqr,

    MAX(
        CASE WHEN price_status = 'ZERO IQR' THEN 1 ELSE 0 END
    ) AS zero_iqr_flag

FROM classified_prices

GROUP BY
    category_tag,
    currency_code,
    price_per

HAVING MAX(observation_count) >= 10

ORDER BY high_outlier_rate_pct DESC;



-- ============================================================
-- QUERY 19: High-Volume Category Outlier Analysis
-- Minimum 30 observations
-- ============================================================

WITH ranked_prices AS (

    SELECT
        dc.category_tag,
        cur.currency_code,
        fc.price_per,
        fc.price,

        ROW_NUMBER() OVER (
            PARTITION BY
                dc.category_tag,
                cur.currency_code,
                fc.price_per
            ORDER BY fc.price
        ) AS price_rank,

        COUNT(*) OVER (
            PARTITION BY
                dc.category_tag,
                cur.currency_code,
                fc.price_per
        ) AS total_observations

    FROM fact_category_observations fc

    INNER JOIN dim_categories dc
        ON fc.category_key = dc.category_key

    INNER JOIN dim_currency cur
        ON fc.currency_key = cur.currency_key

    WHERE fc.price > 0
      AND cur.is_unknown = 0

),

quartiles AS (

    SELECT
        category_tag,
        currency_code,
        price_per,
        COUNT(*) AS observation_count,

        MAX(
            CASE
                WHEN price_rank = CEIL(total_observations * 0.25)
                THEN price
            END
        ) AS q1,

        MAX(
            CASE
                WHEN price_rank = CEIL(total_observations * 0.75)
                THEN price
            END
        ) AS q3

    FROM ranked_prices

    GROUP BY
        category_tag,
        currency_code,
        price_per

    HAVING COUNT(*) >= 30

),

outlier_summary AS (

    SELECT
        rp.category_tag,
        rp.currency_code,
        rp.price_per,

        COUNT(*) AS observation_count,

        SUM(
            CASE
                WHEN rp.price >
                     q.q3 + 1.5 * (q.q3 - q.q1)
                THEN 1
                ELSE 0
            END
        ) AS high_outlier_count,

        q.q1,
        q.q3

    FROM ranked_prices rp

    INNER JOIN quartiles q
        ON rp.category_tag = q.category_tag
       AND rp.currency_code = q.currency_code
       AND rp.price_per = q.price_per

    GROUP BY
        rp.category_tag,
        rp.currency_code,
        rp.price_per,
        q.q1,
        q.q3

)

SELECT
    category_tag,
    currency_code,
    price_per,
    observation_count,
    high_outlier_count,

    ROUND(
        high_outlier_count * 100.0 / observation_count,
        2
    ) AS outlier_rate_pct,

    ROUND(q1, 2) AS q1,
    ROUND(q3, 2) AS q3

FROM outlier_summary

ORDER BY high_outlier_count DESC
LIMIT 20;
