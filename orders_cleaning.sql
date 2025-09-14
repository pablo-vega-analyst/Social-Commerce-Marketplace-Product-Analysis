-- Cleaning Orders Dataset

-- Step 1. Take a Look at the Dataset

DESCRIBE orders;

SELECT *
FROM orders
LIMIT 10;

-- Step 2. Remove Duplicates

-- create staging table and remove duplicates
CREATE TABLE orders_staging AS
SELECT DISTINCT *
FROM orders;

SELECT *
FROM orders_staging
LIMIT 10;

-- Step 3. Look for Inconsistencies, Standardize, and Look for Missing Values

-- remove leading and trailing whitespace from text columns
UPDATE orders_staging
SET order_id = TRIM(order_id);

UPDATE orders_staging
SET user_id = TRIM(user_id);

UPDATE orders_staging
SET product_id = TRIM(product_id);

UPDATE orders_staging
SET order_date = TRIM(order_date);

-- check if there are any strings with incorrect format in the order_id column
-- note that correct format is 'O000000'
-- note that the following query will detect empty strings but not nulls
SELECT
	EXISTS(
		SELECT 1
        FROM orders_staging
        WHERE order_id NOT REGEXP '^O[0-9]{6}$'
    ) AS has_incorrect_format;
    
-- check if there are any strings that have incorrect format in the user_id column
-- note that the correct format is 'U00000'
-- note that the following query will detect empty strings but not nulls
SELECT
	EXISTS(
		SELECT 1
        FROM orders_staging
        WHERE user_id NOT REGEXP '^U[0-9]{5}$'
    ) AS has_incorrect_format;
    
-- check if there are strings with incorrect format in the product_id column
-- note that the correct format is 'P00000'
-- note that the following query will detect empty strings but not nulls
SELECT
	EXISTS(
		SELECT 1
        FROM orders_staging
        WHERE product_id NOT REGEXP '^P[0-9]{5}$'
    ) AS has_incorrect_format;
    
-- check if there are any dates with incorrect format in the order_date column
-- note that the correct format is YYYY-MM-DD
-- note that the following query will detect empty strings but not nulls or incorrect dates like 9999-99-99
SELECT
	EXISTS (
		SELECT 1
        FROM orders_staging
        WHERE order_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
    ) AS had_incorrect_format;
    
-- check if there are incorrect dates such as 9999-99-99
-- note: "STR_TO_DATE(signup_date, '%Y-%m-%d')" will return null for an invalid date like 9999-99-99
SELECT order_date
FROM orders_staging
WHERE STR_TO_DATE(order_date, '%Y-%m-%d') IS NULL;

-- check for invalid values such as zero, negative, decimal, empty strings, and nulls in the num_itmes columns
SELECT DISTINCT num_items
FROM orders_staging;

-- check for any values that are not either 0 or 1 in the bundle_adopted column
SELECT DISTINCT bundle_adopted
FROM orders_staging;

-- check for nulls in the order_id column
SELECT
	EXISTS(
		SELECT 1
        FROM orders_staging
        WHERE order_id IS NULL
    ) AS has_nulls;
    
-- check for nulls in the user_id column
SELECT
	EXISTS(
		SELECT 1
        FROM orders_staging
        WHERE user_id IS NULL
    ) AS has_nulls;
    
-- check for nulls in the product_id column
SELECT
	EXISTS(
		SELECT 1
        FROM orders_staging
        WHERE product_id IS NULL
    ) AS has_nulls;
    
-- check for nulls in the order_date column
SELECT
	EXISTS(
		SELECT 1
        FROM orders_staging
        WHERE order_date IS NULL
    ) AS has_nulls;

-- Step 4. Address Missing Values

-- no missing values to address

-- Step 5. Convert Datatypes of Columns to Appropriate Datatypes

-- change data type of order_date from text to date
ALTER TABLE orders_staging
MODIFY order_date DATE;

-- Step 6. Look at Summary Statistics of Numerical Columms

SELECT
	MIN(num_items),
    MAX(num_items),
    AVG(num_items),
    STDDEV(num_items)
FROM orders_staging;

-- Step 7. Validate Logical Relationships Between Columns

-- no logical relationships between columns to validate