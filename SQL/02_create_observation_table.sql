
-- ============================================================
-- PROJECT 01: RETAIL PRODUCT & PRICE INTELLIGENCE
-- SCRIPT: 02_create_observation_table.sql
--
-- PURPOSE:
-- Create the central price observation table.
-- ============================================================


-- Select the project database.

USE retail_price_intelligence;


-- Create the fact table.

CREATE TABLE IF NOT EXISTS fact_price_observations (

    observation_id BIGINT NOT NULL,

    observation_type VARCHAR(20),

    product_code VARCHAR(50),

    product_name TEXT,

    category_tag VARCHAR(255),

    price DECIMAL(12,3),

    currency VARCHAR(10),

    observation_date DATE,

    is_discounted BOOLEAN,

    original_price DECIMAL(12,3),

    discount_type VARCHAR(50),

    discount_percentage DECIMAL(8,3),

    zero_price_flag BOOLEAN,

    missing_date_flag BOOLEAN,

    source VARCHAR(100),

    PRIMARY KEY (observation_id)

);


-- Verify the table structure.

DESCRIBE fact_price_observations;


-- Display the tables in the database.

SHOW TABLES;