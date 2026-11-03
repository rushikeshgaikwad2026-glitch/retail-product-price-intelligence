
-- ============================================================
-- PROJECT 01: RETAIL PRODUCT & PRICE INTELLIGENCE
-- FILE: 13_create_fact_category_observations.sql
--
-- PURPOSE:
-- Create and populate the category-level fact table.
--
-- SOURCE:
-- stg_open_prices
--
-- EXPECTED SOURCE RECORDS:
-- 10,551 CATEGORY observations
--
-- DIMENSIONS USED:
-- dim_categories
-- dim_locations
-- dim_date
-- dim_currency
-- ============================================================


-- ============================================================
-- STEP 1: CREATE CATEGORY FACT TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS fact_category_observations (

    observation_id BIGINT UNSIGNED NOT NULL,

    category_key BIGINT UNSIGNED NOT NULL,
    location_key BIGINT UNSIGNED NOT NULL,
    date_key INT NULL,
    currency_key SMALLINT UNSIGNED NOT NULL,

    -- Original category identifier
    category_tag VARCHAR(100) NOT NULL,

    -- Price information
    price DECIMAL(14,4) NOT NULL,
    price_per VARCHAR(50) NOT NULL,

    -- Data quality
    zero_price_flag BOOLEAN NOT NULL,

    -- Source information
    source VARCHAR(255) NULL,
    observation_datetime DATETIME(3) NULL,

    -- ETL metadata
    etl_batch_id VARCHAR(100) NULL,
    loaded_at TIMESTAMP NULL,

    PRIMARY KEY (observation_id),

    INDEX idx_cat_fact_category (category_key),
    INDEX idx_cat_fact_location (location_key),
    INDEX idx_cat_fact_date (date_key),
    INDEX idx_cat_fact_currency (currency_key),

    CONSTRAINT fk_cat_fact_category
        FOREIGN KEY (category_key)
        REFERENCES dim_categories(category_key),

    CONSTRAINT fk_cat_fact_location
        FOREIGN KEY (location_key)
        REFERENCES dim_locations(location_key),

    CONSTRAINT fk_cat_fact_date
        FOREIGN KEY (date_key)
        REFERENCES dim_date(date_key),

    CONSTRAINT fk_cat_fact_currency
        FOREIGN KEY (currency_key)
        REFERENCES dim_currency(currency_key)

) ENGINE = InnoDB;


-- ============================================================
-- STEP 2: LOAD CATEGORY OBSERVATIONS
-- ============================================================

INSERT INTO fact_category_observations (

    observation_id,
    category_key,
    location_key,
    date_key,
    currency_key,
    category_tag,
    price,
    price_per,
    zero_price_flag,
    source,
    observation_datetime,
    etl_batch_id,
    loaded_at

)

SELECT

    stg.id,

    dc.category_key,

    dl.location_key,

    dd.date_key,

    dcur.currency_key,

    TRIM(stg.category_tag),

    stg.price,

    UPPER(TRIM(stg.price_per)),

    CASE
        WHEN stg.price = 0 THEN 1
        ELSE 0
    END,

    stg.source,

    stg.date,

    stg.etl_batch_id,

    stg.loaded_at

FROM stg_open_prices stg

INNER JOIN dim_categories dc
    ON TRIM(stg.category_tag) = dc.category_tag

INNER JOIN dim_locations dl
    ON COALESCE(stg.location_id, 0) = dl.location_id

INNER JOIN dim_currency dcur
    ON COALESCE(
        NULLIF(UPPER(TRIM(stg.currency)), ''),
        'UNKNOWN'
    ) = dcur.currency_code

LEFT JOIN dim_date dd
    ON DATE(stg.date) = dd.full_date

WHERE stg.type = 'CATEGORY';


-- ============================================================
-- STEP 3: VALIDATE TOTAL RECORDS
-- ============================================================

SELECT

    COUNT(*) AS total_fact_records,

    COUNT(DISTINCT observation_id) AS unique_observations,

    SUM(zero_price_flag) AS zero_price_records,

    SUM(CASE
        WHEN date_key IS NULL THEN 1
        ELSE 0
    END) AS missing_date_keys

FROM fact_category_observations;


-- ============================================================
-- STEP 4: VALIDATE AGAINST STAGING SOURCE
-- ============================================================

SELECT

    (SELECT COUNT(*)
     FROM stg_open_prices
     WHERE type = 'CATEGORY') AS staging_records,

    (SELECT COUNT(*)
     FROM fact_category_observations) AS fact_records;


-- ============================================================
-- STEP 5: VALIDATE CATEGORY DISTRIBUTION
-- ============================================================

SELECT

    dc.category_tag,

    COUNT(*) AS total_observations,

    ROUND(AVG(f.price), 2) AS average_price

FROM fact_category_observations f

INNER JOIN dim_categories dc
    ON f.category_key = dc.category_key

GROUP BY dc.category_tag

ORDER BY total_observations DESC

LIMIT 20;


-- ============================================================
-- STEP 6: VALIDATE CURRENCY AND MEASUREMENT BASIS
-- ============================================================

SELECT

    dcur.currency_code,

    f.price_per,

    COUNT(*) AS total_observations,

    SUM(f.zero_price_flag) AS zero_price_records

FROM fact_category_observations f

INNER JOIN dim_currency dcur
    ON f.currency_key = dcur.currency_key

GROUP BY
    dcur.currency_code,
    f.price_per

ORDER BY
    total_observations DESC;


-- ============================================================
-- STEP 7: VERIFY THE KNOWN ZERO-PRICE OBSERVATION
-- ============================================================

SELECT

    observation_id,
    category_tag,
    price,
    price_per,
    zero_price_flag

FROM fact_category_observations

WHERE observation_id = 43141;


-- ============================================================
-- END OF FILE 13
-- ============================================================

SELECT

    (SELECT COUNT(*)
     FROM stg_open_prices
     WHERE type = 'CATEGORY') AS staging_records,

    (SELECT COUNT(*)
     FROM fact_category_observations) AS fact_records;


     SELECT
    dc.category_tag,
    COUNT(*) AS total_observations,
    ROUND(AVG(f.price), 2) AS average_price
FROM fact_category_observations f
INNER JOIN dim_categories dc
    ON f.category_key = dc.category_key
GROUP BY dc.category_tag
ORDER BY total_observations DESC
LIMIT 20;


SELECT
    dcur.currency_code,
    f.price_per,
    COUNT(*) AS total_observations,
    SUM(f.zero_price_flag) AS zero_price_records
FROM fact_category_observations f
INNER JOIN dim_currency dcur
    ON f.currency_key = dcur.currency_key
GROUP BY dcur.currency_code, f.price_per
ORDER BY total_observations DESC;

SELECT
    observation_id,
    category_tag,
    price,
    price_per,
    zero_price_flag
FROM fact_category_observations
WHERE observation_id = 43141;


-- ============================================================
-- STEP 8: SOURCE-TO-FACT INTEGRITY VALIDATION
-- ============================================================

SELECT

    COUNT(*) AS source_records,

    SUM(
        CASE
            WHEN f.observation_id IS NULL THEN 1
            ELSE 0
        END
    ) AS missing_fact_records,

    SUM(
        CASE
            WHEN f.observation_id IS NOT NULL
             AND (
                f.category_tag <> TRIM(stg.category_tag)
                OR f.price <> stg.price
                OR f.price_per <> UPPER(TRIM(stg.price_per))
                OR f.zero_price_flag <> CASE
                    WHEN stg.price = 0 THEN 1 ELSE 0
                   END
                OR NOT (f.category_key <=> dc.category_key)
                OR NOT (f.location_key <=> dl.location_key)
                OR NOT (f.currency_key <=> dcur.currency_key)
                OR NOT (f.date_key <=> dd.date_key)
                OR NOT (f.source <=> stg.source)
                OR NOT (f.observation_datetime <=> stg.date)
                OR NOT (f.etl_batch_id <=> stg.etl_batch_id)
                OR NOT (f.loaded_at <=> stg.loaded_at)
             )
            THEN 1
            ELSE 0
        END
    ) AS mismatched_source_records

FROM stg_open_prices stg

LEFT JOIN fact_category_observations f
    ON stg.id = f.observation_id

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