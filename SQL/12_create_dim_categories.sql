
-- ============================================================
-- PROJECT 01: RETAIL PRODUCT & PRICE INTELLIGENCE
-- FILE: 12_create_dim_categories.sql
-- PURPOSE: Create and populate the category dimension
-- SOURCE: stg_open_prices
-- EXPECTED RECORDS: 640 unique categories
-- ============================================================


-- STEP 1: CREATE CATEGORY DIMENSION

CREATE TABLE IF NOT EXISTS dim_categories (

    category_key BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,

    category_tag VARCHAR(100) NOT NULL,

    PRIMARY KEY (category_key),

    UNIQUE KEY uq_category_tag (category_tag)

) ENGINE = InnoDB;


-- STEP 2: POPULATE CATEGORY DIMENSION

INSERT INTO dim_categories (
    category_tag
)

SELECT DISTINCT
    TRIM(category_tag)

FROM stg_open_prices

WHERE type = 'CATEGORY'
  AND category_tag IS NOT NULL
  AND TRIM(category_tag) <> ''

ON DUPLICATE KEY UPDATE
    category_tag = VALUES(category_tag);


-- STEP 3: VALIDATE CATEGORY DIMENSION

SELECT
    COUNT(*) AS total_categories,

    COUNT(DISTINCT category_tag) AS unique_category_tags,

    MIN(category_key) AS first_category_key,

    MAX(category_key) AS last_category_key

FROM dim_categories;


-- STEP 4: CHECK DUPLICATE CATEGORY TAGS

SELECT
    category_tag,
    COUNT(*) AS duplicate_count

FROM dim_categories

GROUP BY category_tag

HAVING COUNT(*) > 1;


-- STEP 5: CHECK MISSING CATEGORY TAGS

SELECT
    COUNT(*) AS missing_category_tags

FROM stg_open_prices

WHERE type = 'CATEGORY'
  AND (
      category_tag IS NULL
      OR TRIM(category_tag) = ''
  );


-- STEP 6: CHECK CATEGORY MAPPING COMPLETENESS

SELECT
    COUNT(*) AS total_category_observations,

    COUNT(dc.category_key) AS mapped_observations,

    SUM(
        CASE
            WHEN dc.category_key IS NULL
            THEN 1 ELSE 0
        END
    ) AS unmapped_observations

FROM stg_open_prices stg

LEFT JOIN dim_categories dc
    ON TRIM(stg.category_tag) = dc.category_tag

WHERE stg.type = 'CATEGORY';


-- ============================================================
-- END OF FILE 12
-- ============================================================
