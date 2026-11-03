-- Price performance by currency


USE retail_price_intelligence;

SELECT
    dc.currency_code,

    COUNT(*) AS total_observations,

    COUNT(DISTINCT f.product_id) AS unique_products,

    ROUND(AVG(f.price), 2) AS average_price,

    ROUND(MIN(f.price), 2) AS minimum_price,

    ROUND(MAX(f.price), 2) AS maximum_price,

    SUM(f.price_is_discounted = 1) AS discounted_observations,

    ROUND(
        100.0 * SUM(f.price_is_discounted = 1) / COUNT(*),
        2
    ) AS discount_percentage

FROM fact_price_observations f

INNER JOIN dim_currency dc
    ON f.currency_key = dc.currency_key

WHERE dc.is_unknown = 0

GROUP BY dc.currency_code

ORDER BY total_observations DESC;




WITH eligible_currencies AS (

    SELECT
        currency_key,
        currency_code
    FROM dim_currency
    WHERE is_unknown = 0
      AND currency_code IN (
          SELECT dc.currency_code
          FROM fact_price_observations f
          INNER JOIN dim_currency dc
              ON f.currency_key = dc.currency_key
          GROUP BY dc.currency_code
          HAVING COUNT(*) >= 1000
      )
),

ranked_prices AS (

    SELECT
        dc.currency_code,
        f.product_id,
        f.product_name,
        f.price,
        f.observation_datetime,

        ROW_NUMBER() OVER (
            PARTITION BY dc.currency_code
            ORDER BY f.price DESC, f.observation_id
        ) AS price_rank

    FROM fact_price_observations f

    INNER JOIN dim_currency dc
        ON f.currency_key = dc.currency_key

    INNER JOIN eligible_currencies ec
        ON dc.currency_code = ec.currency_code

    WHERE f.price IS NOT NULL
      AND f.price > 0
)

SELECT
    currency_code,
    price_rank,
    product_id,
    product_name,
    price,
    observation_datetime

FROM ranked_prices

WHERE price_rank <= 10

ORDER BY currency_code, price_rank;


-- Top 10 products by average price



WITH product_price_summary AS (

    SELECT
        dc.currency_code,
        dp.product_id,
        dp.product_code,

        MAX(NULLIF(TRIM(f.product_name), '')) AS display_name,

        COUNT(*) AS observation_count,

        COUNT(DISTINCT f.location_key) AS locations_observed,

        COUNT(DISTINCT NULLIF(TRIM(f.product_name), ''))
            AS name_variants,

        ROUND(AVG(f.price), 2) AS average_price,
        ROUND(MIN(f.price), 2) AS minimum_price,
        ROUND(MAX(f.price), 2) AS maximum_price

    FROM fact_price_observations f

    INNER JOIN dim_products dp
        ON f.product_id = dp.product_id

    INNER JOIN dim_currency dc
        ON f.currency_key = dc.currency_key

    WHERE dc.is_unknown = 0
      AND f.price > 0

    GROUP BY
        dc.currency_code,
        dp.product_id,
        dp.product_code

    HAVING COUNT(*) >= 3
       AND COUNT(DISTINCT NULLIF(TRIM(f.product_name), '')) > 0
),

ranked_products AS (

    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY currency_code
            ORDER BY average_price DESC
        ) AS price_rank

    FROM product_price_summary
)

SELECT
    currency_code,
    price_rank,
    product_id,
    product_code,
    display_name,
    observation_count,
    locations_observed,
    name_variants,
    average_price,
    minimum_price,
    maximum_price

FROM ranked_products

WHERE price_rank <= 10

ORDER BY currency_code, price_rank;





-- QUERY 4: Price variation across locations
-- Compare the same product within the same currency.

WITH location_price_summary AS (

    SELECT
        dc.currency_code,
        dp.product_id,
        dp.product_code,

        MAX(NULLIF(TRIM(f.product_name), '')) AS display_name,

        dl.location_key,
        dl.location_id,

        COUNT(*) AS location_observations,

        ROUND(AVG(f.price), 2) AS location_average_price

    FROM fact_price_observations f

    INNER JOIN dim_products dp
        ON f.product_id = dp.product_id

    INNER JOIN dim_locations dl
        ON f.location_key = dl.location_key

    INNER JOIN dim_currency dc
        ON f.currency_key = dc.currency_key

    WHERE dc.is_unknown = 0
      AND f.price > 0

    GROUP BY
        dc.currency_code,
        dp.product_id,
        dp.product_code,
        dl.location_key,
        dl.location_id

    HAVING COUNT(*) >= 2
),

product_location_variation AS (

    SELECT
        currency_code,
        product_id,
        product_code,

        MAX(display_name) AS display_name,

        COUNT(DISTINCT location_key) AS locations_compared,

        SUM(location_observations) AS total_observations,

        ROUND(MIN(location_average_price), 2)
            AS lowest_location_average,

        ROUND(MAX(location_average_price), 2)
            AS highest_location_average,

        ROUND(AVG(location_average_price), 2)
            AS average_of_location_averages

    FROM location_price_summary

    GROUP BY
        currency_code,
        product_id,
        product_code

    HAVING COUNT(DISTINCT location_key) >= 2
),

ranked_variation AS (

    SELECT
        *,

        ROUND(
            highest_location_average - lowest_location_average,
            2
        ) AS absolute_price_difference,

        ROUND(
            100.0 *
            (highest_location_average - lowest_location_average)
            / NULLIF(lowest_location_average, 0),
            2
        ) AS price_variation_percentage,

        ROW_NUMBER() OVER (
            PARTITION BY currency_code
            ORDER BY
                (
                    highest_location_average -
                    lowest_location_average
                ) / NULLIF(lowest_location_average, 0) DESC
        ) AS variation_rank

    FROM product_location_variation
)

SELECT
    currency_code,
    variation_rank,
    product_id,
    product_code,
    display_name,
    locations_compared,
    total_observations,
    lowest_location_average,
    highest_location_average,
    absolute_price_difference,
    price_variation_percentage

FROM ranked_variation

WHERE variation_rank <= 10

ORDER BY
    currency_code,
    variation_rank;


-- QUERY 5: Investigate high price variation
-- Inspect individual observations for selected EUR products.

SELECT
    dp.product_id,
    dp.product_code,
    f.product_name,

    dl.location_id,
    dl.location_name,
    dl.city,
    dl.country,

    f.price,
    dc.currency_code,
    f.price_per,
    f.receipt_quantity,

    dd.full_date,

    f.price_is_discounted,
    f.price_without_discount,
    f.discount_percentage

FROM fact_price_observations f

INNER JOIN dim_products dp
    ON f.product_id = dp.product_id

INNER JOIN dim_locations dl
    ON f.location_key = dl.location_key

INNER JOIN dim_currency dc
    ON f.currency_key = dc.currency_key

LEFT JOIN dim_date dd
    ON f.date_key = dd.date_key

WHERE dp.product_id IN (84424, 66922, 56383)
  AND dc.currency_code = 'EUR'
  AND f.price > 0

ORDER BY
    dp.product_id,
    dl.location_id,
    dd.full_date;


    -- QUERY 6: Investigate suspicious individual observations
-- Bring original staging metadata back into the analysis.

SELECT
    f.observation_id,
    dp.product_id,
    dp.product_code,
    f.product_name,

    dl.location_id,
    dl.city,

    f.price,
    f.receipt_quantity,
    f.price_per,

    dd.full_date,

    stg.proof_type,
    stg.proof_date,
    stg.proof_receipt_price_count,
    stg.proof_receipt_price_total,
    stg.source,
    stg.proof_source

FROM fact_price_observations f

INNER JOIN dim_products dp
    ON f.product_id = dp.product_id

INNER JOIN dim_locations dl
    ON f.location_key = dl.location_key

INNER JOIN dim_currency dc
    ON f.currency_key = dc.currency_key

LEFT JOIN dim_date dd
    ON f.date_key = dd.date_key

LEFT JOIN stg_open_prices stg
    ON f.observation_id = stg.id

WHERE dp.product_id IN (56383, 66922, 84424)
  AND dc.currency_code = 'EUR'
  AND f.price > 0

ORDER BY
    dp.product_id,
    dd.full_date,
    dl.location_id,
    f.price;


-- QUERY 7: Check repeated observations
-- Identify identical business attributes with multiple source IDs.

SELECT
    dp.product_id,
    dp.product_code,

    f.location_key,
    f.observation_datetime,
    f.price,
    f.product_name,
    f.source,

    COUNT(*) AS matching_records,

    GROUP_CONCAT(
        f.observation_id
        ORDER BY f.observation_id
    ) AS observation_ids

FROM fact_price_observations f

INNER JOIN dim_products dp
    ON f.product_id = dp.product_id

WHERE f.product_id = 56383
  AND f.location_key = (
      SELECT location_key
      FROM dim_locations
      WHERE location_id = 406
  )
  AND f.price = 1.26

GROUP BY
    dp.product_id,
    dp.product_code,
    f.location_key,
    f.observation_datetime,
    f.price,
    f.product_name,
    f.source

HAVING COUNT(*) > 1;




DESCRIBE dim_date;

-- QUERY 8: Monthly price trend for EUR observations

SELECT
    dd.year_number,
    dd.month_number,
    dd.month_name,

    COUNT(*) AS total_observations,

    COUNT(DISTINCT f.product_id) AS unique_products,

    ROUND(AVG(f.price), 2) AS average_observed_price,

    ROUND(MIN(f.price), 2) AS minimum_price,

    ROUND(MAX(f.price), 2) AS maximum_price

FROM fact_price_observations f

INNER JOIN dim_currency dc
    ON f.currency_key = dc.currency_key

INNER JOIN dim_date dd
    ON f.date_key = dd.date_key

WHERE dc.currency_code = 'EUR'
  AND f.price > 0

GROUP BY
    dd.year_number,
    dd.month_number,
    dd.month_name

ORDER BY
    dd.year_number,
    dd.month_number;


    -- QUERY 9: Investigate the October 2025 EUR price spike

SELECT
    f.product_id,
    dp.product_code,

    f.product_name,

    COUNT(*) AS observation_count,

    ROUND(AVG(f.price), 2) AS average_price,

    ROUND(MIN(f.price), 2) AS minimum_price,

    ROUND(MAX(f.price), 2) AS maximum_price,

    f.price_per

FROM fact_price_observations f

INNER JOIN dim_products dp
    ON f.product_id = dp.product_id

INNER JOIN dim_currency dc
    ON f.currency_key = dc.currency_key

INNER JOIN dim_date dd
    ON f.date_key = dd.date_key

WHERE dc.currency_code = 'EUR'
  AND dd.year_number = 2025
  AND dd.month_number = 10
  AND f.price > 0

GROUP BY
    f.product_id,
    dp.product_code,
    f.product_name,
    f.price_per

ORDER BY
    average_price DESC

LIMIT 20;


-- QUERY 10: Monthly average vs median EUR price
-- Calculate median using window functions.
-- This avoids GROUP_CONCAT truncation.

WITH monthly_prices AS (

    SELECT
        dd.year_number,
        dd.month_number,
        dd.month_name,
        f.price,

        ROW_NUMBER() OVER (
            PARTITION BY dd.year_number, dd.month_number
            ORDER BY f.price
        ) AS price_rank,

        COUNT(*) OVER (
            PARTITION BY dd.year_number, dd.month_number
        ) AS monthly_count

    FROM fact_price_observations f

    INNER JOIN dim_currency dc
        ON f.currency_key = dc.currency_key

    INNER JOIN dim_date dd
        ON f.date_key = dd.date_key

    WHERE dc.currency_code = 'EUR'
      AND f.price > 0
),

monthly_summary AS (

    SELECT
        year_number,
        month_number,
        month_name,

        COUNT(*) AS total_observations,

        ROUND(AVG(price), 2) AS average_price,

        ROUND(
            AVG(
                CASE
                    WHEN price_rank IN (
                        FLOOR((monthly_count + 1) / 2),
                        FLOOR((monthly_count + 2) / 2)
                    )
                    THEN price
                END
            ),
            2
        ) AS median_price

    FROM monthly_prices

    GROUP BY
        year_number,
        month_number,
        month_name

)

SELECT *
FROM monthly_summary
ORDER BY year_number, month_number;



-- QUERY 11: Annual EUR price performance
-- Compare average and median prices year by year.

WITH annual_prices AS (

    SELECT
        dd.year_number,
        f.price,

        ROW_NUMBER() OVER (
            PARTITION BY dd.year_number
            ORDER BY f.price
        ) AS price_rank,

        COUNT(*) OVER (
            PARTITION BY dd.year_number
        ) AS annual_count

    FROM fact_price_observations f

    INNER JOIN dim_currency dc
        ON f.currency_key = dc.currency_key

    INNER JOIN dim_date dd
        ON f.date_key = dd.date_key

    WHERE dc.currency_code = 'EUR'
      AND f.price > 0
),

annual_summary AS (

    SELECT
        year_number,

        COUNT(*) AS total_observations,

        ROUND(AVG(price), 2) AS average_price,

        ROUND(
            AVG(
                CASE
                    WHEN price_rank IN (
                        FLOOR((annual_count + 1) / 2),
                        FLOOR((annual_count + 2) / 2)
                    )
                    THEN price
                END
            ),
            2
        ) AS median_price

    FROM annual_prices

    GROUP BY year_number
)

SELECT
    year_number,
    total_observations,
    average_price,
    median_price

FROM annual_summary

ORDER BY year_number;


-- QUERY 12: Category-wise EUR price performance
-- Exploratory analysis using CATEGORY observations in staging.

WITH category_prices AS (

    SELECT
        s.category_tag,
        s.price,

        ROW_NUMBER() OVER (
            PARTITION BY s.category_tag
            ORDER BY s.price
        ) AS price_rank,

        COUNT(*) OVER (
            PARTITION BY s.category_tag
        ) AS category_count

    FROM stg_open_prices s

    WHERE s.type = 'CATEGORY'
      AND s.currency = 'EUR'
      AND s.price > 0
      AND s.category_tag IS NOT NULL
      AND TRIM(s.category_tag) <> ''
),

category_summary AS (

    SELECT
        category_tag,

        COUNT(*) AS total_observations,

        ROUND(AVG(price), 2) AS average_price,

        ROUND(
            AVG(
                CASE
                    WHEN price_rank IN (
                        FLOOR((category_count + 1) / 2),
                        FLOOR((category_count + 2) / 2)
                    )
                    THEN price
                END
            ),
            2
        ) AS median_price,

        ROUND(MIN(price), 2) AS minimum_price,
        ROUND(MAX(price), 2) AS maximum_price

    FROM category_prices

    GROUP BY category_tag
)

SELECT *
FROM category_summary
WHERE total_observations >= 10
ORDER BY total_observations DESC
LIMIT 20;


-- QUERY 13: Category observation coverage and unit analysis

SELECT
    s.category_tag,

    COUNT(*) AS total_observations,

    COUNT(DISTINCT s.location_id) AS unique_locations,

    COUNT(DISTINCT s.price_per) AS distinct_price_units,

    GROUP_CONCAT(
        DISTINCT COALESCE(NULLIF(TRIM(s.price_per), ''), 'Not Specified')
        ORDER BY s.price_per
        SEPARATOR ', '
    ) AS price_units,

    COUNT(DISTINCT s.currency) AS distinct_currencies,

    MIN(s.date) AS first_observation_date,

    MAX(s.date) AS latest_observation_date,

    ROUND(AVG(s.price), 2) AS average_price,

    ROUND(MIN(s.price), 2) AS minimum_price,

    ROUND(MAX(s.price), 2) AS maximum_price

FROM stg_open_prices s

WHERE s.type = 'CATEGORY'
  AND s.currency = 'EUR'
  AND s.price > 0
  AND s.category_tag IS NOT NULL
  AND TRIM(s.category_tag) <> ''

GROUP BY s.category_tag

HAVING COUNT(*) >= 10

ORDER BY total_observations DESC

LIMIT 20;


-- QUERY 14: Category price analysis by measurement unit

SELECT
    s.category_tag,

    s.price_per,

    COUNT(*) AS total_observations,

    COUNT(DISTINCT s.location_id) AS unique_locations,

    ROUND(AVG(s.price), 2) AS average_price,

    ROUND(MIN(s.price), 2) AS minimum_price,

    ROUND(MAX(s.price), 2) AS maximum_price,

    MIN(s.date) AS first_observation,

    MAX(s.date) AS latest_observation

FROM stg_open_prices s

WHERE s.type = 'CATEGORY'
  AND s.currency = 'EUR'
  AND s.price > 0
  AND s.category_tag IS NOT NULL
  AND TRIM(s.category_tag) <> ''
  AND s.price_per IS NOT NULL

GROUP BY
    s.category_tag,
    s.price_per

HAVING COUNT(*) >= 10

ORDER BY
    s.category_tag,
    total_observations DESC;



    -- QUERY 15: Measurement-basis completeness
-- Includes missing and blank price_per values.

SELECT
    COALESCE(
        NULLIF(UPPER(TRIM(price_per)), ''),
        'NOT SPECIFIED'
    ) AS measurement_basis,

    COUNT(*) AS total_observations,

    COUNT(DISTINCT category_tag) AS unique_categories,

    COUNT(DISTINCT location_id) AS unique_locations,

    MIN(date) AS first_observation,

    MAX(date) AS latest_observation

FROM stg_open_prices

WHERE type = 'CATEGORY'
  AND currency = 'EUR'
  AND price > 0

GROUP BY
    COALESCE(
        NULLIF(UPPER(TRIM(price_per)), ''),
        'NOT SPECIFIED'
    )

ORDER BY total_observations DESC;


-- QUERY 16: Complete CATEGORY observation quality

SELECT
    COALESCE(
        NULLIF(UPPER(TRIM(currency)), ''),
        'NOT SPECIFIED'
    ) AS currency_code,

    COALESCE(
        NULLIF(UPPER(TRIM(price_per)), ''),
        'NOT SPECIFIED'
    ) AS measurement_basis,

    COUNT(*) AS total_observations,

    SUM(
        CASE
            WHEN price IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_prices,

    SUM(
        CASE
            WHEN price = 0 THEN 1
            ELSE 0
        END
    ) AS zero_prices,

    SUM(
        CASE
            WHEN category_tag IS NULL
              OR TRIM(category_tag) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_category_tags

FROM stg_open_prices

WHERE type = 'CATEGORY'

GROUP BY
    COALESCE(
        NULLIF(UPPER(TRIM(currency)), ''),
        'NOT SPECIFIED'
    ),
    COALESCE(
        NULLIF(UPPER(TRIM(price_per)), ''),
        'NOT SPECIFIED'
    )

ORDER BY
    total_observations DESC;





    -- Check the complete CATEGORY population
SELECT
    COUNT(*) AS total_category_records,

    SUM(
        CASE WHEN currency IS NULL
             OR TRIM(currency) = ''
             THEN 1 ELSE 0 END
    ) AS missing_currency,

    SUM(
        CASE WHEN price_per IS NULL
             OR TRIM(price_per) = ''
             THEN 1 ELSE 0 END
    ) AS missing_measurement_basis,

    SUM(
        CASE WHEN currency IS NULL
             OR TRIM(currency) = ''
             OR price_per IS NULL
             OR TRIM(price_per) = ''
             THEN 1 ELSE 0 END
    ) AS missing_currency_or_basis

FROM stg_open_prices
WHERE type = 'CATEGORY';

SELECT
    id,
    category_tag,
    price,
    currency,
    price_per,
    date,
    location_id
FROM stg_open_prices
WHERE type = 'CATEGORY'
  AND price = 0;