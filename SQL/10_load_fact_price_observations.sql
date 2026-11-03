USE retail_price_intelligence;

INSERT INTO fact_price_observations (
    observation_id,
    product_id,
    location_key,
    date_key,
    currency_key,
    product_name,
    price,
    price_without_discount,
    price_is_discounted,
    discount_type,
    discount_percentage,
    price_per,
    receipt_quantity,
    zero_price_flag,
    missing_date_flag,
    source,
    observation_datetime,
    etl_batch_id,
    loaded_at
)

SELECT
    stg.id,
    dp.product_id,
    dl.location_key,
    dd.date_key,
    dc.currency_key,
    stg.product_name,
    stg.price,
    stg.price_without_discount,
    stg.price_is_discounted,
    stg.discount_type,
    stg.discount_percentage,
    stg.price_per,
    stg.receipt_quantity,
    stg.zero_price_flag,
    stg.missing_date_flag,
    stg.source,
    stg.date,
    stg.etl_batch_id,
    stg.loaded_at

FROM stg_open_prices stg

INNER JOIN dim_products dp
    ON stg.product_code = dp.product_code

INNER JOIN dim_locations dl
    ON COALESCE(stg.location_id, 0) = dl.location_id

INNER JOIN dim_currency dc
    ON COALESCE(
        NULLIF(UPPER(TRIM(stg.currency)), ''),
        'UNKNOWN'
    ) = UPPER(TRIM(dc.currency_code))

LEFT JOIN dim_date dd
    ON DATE(stg.date) = dd.full_date

WHERE stg.type = 'PRODUCT';

SELECT COUNT(*) AS total_fact_records
FROM fact_price_observations;

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT observation_id) AS unique_observations
FROM fact_price_observations;


-- Data quality verification
SELECT
    SUM(zero_price_flag = 1) AS zero_price_records,
    SUM(missing_date_flag = 1) AS missing_date_records,
    SUM(date_key IS NULL) AS null_date_keys,
    SUM(price_is_discounted = 1) AS discounted_records
FROM fact_price_observations;

-- Verify all foreign-key mappings

SELECT
    SUM(dp.product_id IS NULL) AS invalid_products,
    SUM(dl.location_key IS NULL) AS invalid_locations,
    SUM(dc.currency_key IS NULL) AS invalid_currencies,
    SUM(dd.date_key IS NULL AND f.date_key IS NOT NULL) AS invalid_dates
FROM fact_price_observations f
LEFT JOIN dim_products dp
    ON f.product_id = dp.product_id
LEFT JOIN dim_locations dl
    ON f.location_key = dl.location_key
LEFT JOIN dim_currency dc
    ON f.currency_key = dc.currency_key
LEFT JOIN dim_date dd
    ON f.date_key = dd.date_key;



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
        CASE WHEN category_tag IS NULL
             OR TRIM(category_tag) = ''
             THEN 1 ELSE 0 END
    ) AS missing_category_tag

FROM stg_open_prices
WHERE type = 'CATEGORY';


WITH category_counts AS (
    SELECT
        COALESCE(
            NULLIF(UPPER(TRIM(currency)), ''),
            'NOT SPECIFIED'
        ) AS currency_code,

        COALESCE(
            NULLIF(UPPER(TRIM(price_per)), ''),
            'NOT SPECIFIED'
        ) AS measurement_basis,

        COUNT(*) AS total_observations

    FROM stg_open_prices
    WHERE type = 'CATEGORY'

    GROUP BY
        COALESCE(NULLIF(UPPER(TRIM(currency)), ''), 'NOT SPECIFIED'),
        COALESCE(NULLIF(UPPER(TRIM(price_per)), ''), 'NOT SPECIFIED')
)

SELECT
    currency_code,
    measurement_basis,
    total_observations
FROM category_counts

UNION ALL

SELECT
    'GRAND TOTAL',
    'ALL',
    SUM(total_observations)
FROM category_counts;


SELECT
    COUNT(DISTINCT TRIM(category_tag)) AS unique_categories,

    MAX(CHAR_LENGTH(TRIM(category_tag))) AS maximum_tag_length,

    SUM(
        CASE
            WHEN TRIM(category_tag) = ''
            THEN 1 ELSE 0
        END
    ) AS blank_category_tags

FROM stg_open_prices
WHERE type = 'CATEGORY';

CREATE TABLE dim_categories (

    category_key BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    category_tag VARCHAR(100) NOT NULL,

    PRIMARY KEY (category_key),

    UNIQUE KEY uq_category_tag (category_tag)

) ENGINE = InnoDB;


INSERT INTO dim_categories (
    category_tag
)

SELECT DISTINCT
    TRIM(category_tag)

FROM stg_open_prices

WHERE type = 'CATEGORY'
  AND category_tag IS NOT NULL
  AND TRIM(category_tag) <> '';

  SELECT
    COUNT(*) AS total_categories,
    COUNT(DISTINCT category_tag) AS unique_category_tags,
    MIN(category_key) AS first_category_key,
    MAX(category_key) AS last_category_key
FROM dim_categories;


SELECT
    COUNT(*) AS total_category_records,

    SUM(CASE
        WHEN dc.category_key IS NULL
        THEN 1 ELSE 0
    END) AS missing_category_mappings,

    SUM(CASE
        WHEN dl.location_key IS NULL
        THEN 1 ELSE 0
    END) AS missing_location_mappings,

    SUM(CASE
        WHEN dcur.currency_key IS NULL
        THEN 1 ELSE 0
    END) AS missing_currency_mappings,

    SUM(CASE
        WHEN dd.date_key IS NULL
             AND stg.date IS NOT NULL
        THEN 1 ELSE 0
    END) AS missing_valid_date_mappings,

    SUM(CASE
        WHEN stg.date IS NULL
        THEN 1 ELSE 0
    END) AS missing_source_dates

FROM stg_open_prices stg

LEFT JOIN dim_categories dc
    ON TRIM(stg.category_tag) = dc.category_tag

LEFT JOIN dim_locations dl
    ON COALESCE(stg.location_id, 0) = dl.location_id

LEFT JOIN dim_currency dcur
    ON COALESCE(
        NULLIF(UPPER(TRIM(stg.currency)), ''),
        'UNKNOWN'
    ) = dcur.currency_code

LEFT JOIN dim_date dd
    ON DATE(stg.date) = dd.full_date

WHERE stg.type = 'CATEGORY';


SELECT
    stg.id AS observation_id,
    stg.category_tag,
    stg.date AS unmatched_date,
    stg.currency,
    stg.price,
    stg.price_per

FROM stg_open_prices stg

LEFT JOIN dim_date dd
    ON DATE(stg.date) = dd.full_date

WHERE stg.type = 'CATEGORY'
  AND stg.date IS NOT NULL
  AND dd.date_key IS NULL;


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

WITH RECURSIVE calendar_dates AS (

    SELECT DATE('2009-04-09') AS calendar_date

    UNION ALL

    SELECT DATE_ADD(calendar_date, INTERVAL 1 DAY)
    FROM calendar_dates
    WHERE calendar_date < '2010-07-07'
)

SELECT
    YEAR(calendar_date) * 10000
        + MONTH(calendar_date) * 100
        + DAY(calendar_date),

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
        THEN 1
        ELSE 0
    END

FROM calendar_dates;
SELECT
    COUNT(*) AS total_calendar_dates,
    MIN(full_date) AS earliest_date,
    MAX(full_date) AS latest_date,
    COUNT(DISTINCT full_date) AS unique_dates
FROM dim_date;


SELECT
    COUNT(*) AS total_category_records,

    SUM(CASE
        WHEN dc.category_key IS NULL
        THEN 1 ELSE 0
    END) AS missing_category_mappings,

    SUM(CASE
        WHEN dl.location_key IS NULL
        THEN 1 ELSE 0
    END) AS missing_location_mappings,

    SUM(CASE
        WHEN dcur.currency_key IS NULL
        THEN 1 ELSE 0
    END) AS missing_currency_mappings,

    SUM(CASE
        WHEN dd.date_key IS NULL
             AND stg.date IS NOT NULL
        THEN 1 ELSE 0
    END) AS missing_valid_date_mappings,

    SUM(CASE
        WHEN stg.date IS NULL
        THEN 1 ELSE 0
    END) AS missing_source_dates

FROM stg_open_prices stg

LEFT JOIN dim_categories dc
    ON TRIM(stg.category_tag) = dc.category_tag

LEFT JOIN dim_locations dl
    ON COALESCE(stg.location_id, 0) = dl.location_id

LEFT JOIN dim_currency dcur
    ON COALESCE(
        NULLIF(UPPER(TRIM(stg.currency)), ''),
        'UNKNOWN'
    ) = dcur.currency_code

LEFT JOIN dim_date dd
    ON DATE(stg.date) = dd.full_date

WHERE stg.type = 'CATEGORY';