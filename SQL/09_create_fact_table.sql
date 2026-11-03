USE retail_price_intelligence;

CREATE TABLE fact_price_observations (

    -- Original source observation ID
    observation_id BIGINT UNSIGNED NOT NULL,

    -- Dimension foreign keys
    product_id BIGINT UNSIGNED NOT NULL,
    location_key BIGINT UNSIGNED NOT NULL,
    date_key INT NULL,
    currency_key SMALLINT UNSIGNED NOT NULL,

    -- Product and price details
    product_name TEXT NULL,
    price DECIMAL(14,4) NOT NULL,
    price_without_discount DECIMAL(14,4) NULL,
    price_is_discounted BOOLEAN NOT NULL,
    discount_type VARCHAR(100) NULL,
    discount_percentage DECIMAL(8,3) NULL,
    price_per VARCHAR(50) NULL,
    receipt_quantity DECIMAL(12,4) NULL,

    -- Data quality flags
    zero_price_flag BOOLEAN NOT NULL,
    missing_date_flag BOOLEAN NOT NULL,

    -- Source and ETL metadata
    source VARCHAR(255) NULL,
    observation_datetime DATETIME(3) NULL,
    etl_batch_id VARCHAR(100) NULL,
    loaded_at TIMESTAMP NULL,

    -- Primary key
    PRIMARY KEY (observation_id),

    -- Foreign keys
    CONSTRAINT fk_fact_product
        FOREIGN KEY (product_id)
        REFERENCES dim_products(product_id),

    CONSTRAINT fk_fact_location
        FOREIGN KEY (location_key)
        REFERENCES dim_locations(location_key),

    CONSTRAINT fk_fact_date
        FOREIGN KEY (date_key)
        REFERENCES dim_date(date_key),

    CONSTRAINT fk_fact_currency
        FOREIGN KEY (currency_key)
        REFERENCES dim_currency(currency_key),

    -- Analytical indexes
    INDEX idx_fact_product (product_id),
    INDEX idx_fact_location (location_key),
    INDEX idx_fact_date (date_key),
    INDEX idx_fact_currency (currency_key)

) ENGINE = InnoDB;


DESCRIBE fact_price_observations;

SHOW CREATE TABLE fact_price_observations;

SELECT COUNT(*) AS fact_records
FROM fact_price_observations;


USE retail_price_intelligence;

SELECT
    COUNT(*) AS total_product_records,

    SUM(dp.product_id IS NULL) AS missing_product_mappings,

    SUM(dl.location_key IS NULL) AS missing_location_mappings,

    SUM(dc.currency_key IS NULL) AS missing_currency_mappings,

    SUM(
        stg.date IS NOT NULL
        AND dd.date_key IS NULL
    ) AS missing_valid_date_mappings,

    SUM(stg.date IS NULL) AS missing_source_dates

FROM stg_open_prices stg

LEFT JOIN dim_products dp
    ON stg.product_code = dp.product_code

LEFT JOIN dim_locations dl
    ON COALESCE(stg.location_id, 0) = dl.location_id

LEFT JOIN dim_currency dc
    ON COALESCE(
        NULLIF(UPPER(TRIM(stg.currency)), ''),
        'UNKNOWN'
    ) = UPPER(TRIM(dc.currency_code))

LEFT JOIN dim_date dd
    ON DATE(stg.date) = dd.full_date

WHERE stg.type = 'PRODUCT';

SELECT COUNT(*) AS existing_fact_records
FROM fact_price_observations;