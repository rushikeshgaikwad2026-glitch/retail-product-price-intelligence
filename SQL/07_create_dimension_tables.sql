USE retail_price_intelligence;

-- 1. Product dimension
CREATE TABLE IF NOT EXISTS dim_products (

    product_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    product_code VARCHAR(50) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_product_code (product_code)

);

-- 2. Product name dimension
CREATE TABLE IF NOT EXISTS dim_product_names (

    product_name_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    product_id BIGINT UNSIGNED NOT NULL,

    product_name VARCHAR(1000) NOT NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE KEY uq_product_name (product_id, product_name(255)),

    CONSTRAINT fk_product_names_product
        FOREIGN KEY (product_id)
        REFERENCES dim_products(product_id)

);

-- 3. Location dimension
CREATE TABLE IF NOT EXISTS dim_locations (

    location_key BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    location_id BIGINT UNSIGNED NOT NULL,

    location_osm_id BIGINT UNSIGNED NULL,

    location_osm_type VARCHAR(50),

    location_name TEXT,

    city VARCHAR(255),

    country VARCHAR(255),

    country_code VARCHAR(20),

    postcode VARCHAR(100),

    latitude DECIMAL(10,7),

    longitude DECIMAL(10,7),

    location_website_url TEXT,

    location_source VARCHAR(255),

    is_geography_incomplete BOOLEAN NOT NULL DEFAULT FALSE,

    has_osm_mapping_variation BOOLEAN NOT NULL DEFAULT FALSE,

    UNIQUE KEY uq_location_id (location_id)

);


-- 4. Date dimension
CREATE TABLE IF NOT EXISTS dim_date (

    date_key INT PRIMARY KEY,

    full_date DATE NOT NULL UNIQUE,

    day_number TINYINT,

    month_number TINYINT,

    month_name VARCHAR(20),

    quarter_number TINYINT,

    year_number SMALLINT,

    day_of_week_number TINYINT,

    day_name VARCHAR(20),

    is_weekend BOOLEAN

);


-- 5. Currency dimension
CREATE TABLE IF NOT EXISTS dim_currency (

    currency_key SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    currency_code VARCHAR(10) NOT NULL,

    currency_name VARCHAR(100),

    is_unknown BOOLEAN NOT NULL DEFAULT FALSE,

    UNIQUE KEY uq_currency_code (currency_code)

);

SHOW TABLES;

DESCRIBE dim_products;
DESCRIBE dim_product_names;
DESCRIBE dim_locations;
DESCRIBE dim_date;
DESCRIBE dim_currency;