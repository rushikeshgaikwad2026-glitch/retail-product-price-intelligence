
-- ============================================================
-- PROJECT 01: RETAIL PRODUCT & PRICE INTELLIGENCE
-- SCRIPT: 01_create_database.sql
--
-- PURPOSE:
-- Create the MySQL database for our retail analytics project.
-- ============================================================


-- 1. Create the project database

CREATE DATABASE IF NOT EXISTS retail_price_intelligence;


-- 2. Select the database for further operations

USE retail_price_intelligence;


-- 3. Display the active database

SELECT DATABASE();


-- 4. Verify database creation

SHOW DATABASES;
