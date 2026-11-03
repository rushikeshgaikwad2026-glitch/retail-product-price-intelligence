
USE retail_price_intelligence;

CREATE TABLE IF NOT EXISTS stg_open_prices (

    -- Observation identification
    id BIGINT UNSIGNED NOT NULL,
    `type` VARCHAR(20),
    product_code VARCHAR(50),
    product_name TEXT,
    category_tag VARCHAR(255),

    -- Product classification
    labels_tags LONGTEXT,
    origins_tags LONGTEXT,

    -- Price information
    price DECIMAL(14,4),
    price_is_discounted BOOLEAN NOT NULL,
    price_without_discount DECIMAL(14,4),
    discount_type VARCHAR(100),
    price_per VARCHAR(50),
    currency VARCHAR(10),

    -- Location identification
    location_osm_id BIGINT UNSIGNED,
    location_osm_type VARCHAR(50),
    location_id BIGINT UNSIGNED,

    -- Observation date
    `date` DATETIME(3),

    -- Proof and receipt information
    proof_id BIGINT UNSIGNED,
    receipt_quantity DECIMAL(12,4),
    `owner` VARCHAR(255),
    `source` VARCHAR(255),
    created DATETIME(6),
    updated DATETIME(6),
    proof_file_path TEXT,
    proof_mimetype VARCHAR(100),
    proof_type VARCHAR(100),
    proof_date DATE,
    proof_currency VARCHAR(10),
    proof_receipt_price_count INT,
    proof_receipt_price_total DECIMAL(14,4),
    proof_owner VARCHAR(255),
    proof_source VARCHAR(255),
    proof_created DATETIME(6),
    proof_updated DATETIME(6),

    -- Location details
    location_type VARCHAR(100),
    location_osm_display_name TEXT,
    location_osm_tag_key VARCHAR(255),
    location_osm_tag_value VARCHAR(255),
    location_osm_address_postcode VARCHAR(100),
    location_osm_address_city VARCHAR(255),
    location_osm_address_country VARCHAR(255),
    location_osm_address_country_code VARCHAR(20),
    location_osm_lat DECIMAL(10,7),
    location_osm_lon DECIMAL(10,7),
    location_website_url TEXT,
    location_source VARCHAR(255),
    location_created DATETIME(6),
    location_updated DATETIME(6),

    -- Derived cleaning columns
    zero_price_flag BOOLEAN NOT NULL,
    discount_percentage DECIMAL(8,3),
    missing_date_flag BOOLEAN NOT NULL,

    -- ETL tracking metadata
    etl_batch_id VARCHAR(100),
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (id)

);

-- Verify table creation
DESCRIBE stg_open_prices;

SHOW TABLES;