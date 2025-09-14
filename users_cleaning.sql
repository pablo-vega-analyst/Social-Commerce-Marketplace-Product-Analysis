-- Cleaning Users Dataset

-- Step 1. Take a Look at the Dataset

-- look at the columns and their datatypes
DESCRIBE users;

-- look at the first 10 rows
SELECT *
FROM users
LIMIT 10;

-- Step 2. Remove Duplicates

-- create staging table and remove duplicates
CREATE TABLE users_staging AS
SELECT DISTINCT *
FROM users;

SELECT *
FROM users_staging
LIMIT 10;

-- Step 3. Look for Incosistencies, Stanardize, and Look for Missing Values

-- remove leading and trailing whitespace from text columns
UPDATE users_staging
SET user_id = TRIM(user_id);

UPDATE users_staging
SET signup_date = TRIM(signup_date);

UPDATE users_staging
SET region = TRIM(region);

UPDATE users_staging
SET device = TRIM(device);

UPDATE users_staging
SET platform = TRIM(platform);

UPDATE users_staging
SET buyer_type = TRIM(buyer_type);

-- check if there are any user ids that have incorrect format
-- note: correct format is 'U00000'
-- note: the folling query will detect empty strings, but not nulls
SELECT
	EXISTS(
		SELECT 1
        FROM users_staging
        WHERE user_id NOT REGEXP '^U[0-9]{5}$'
    ) AS has_incorrect_format;
    
-- check if there are any signup dates that have incorrect format
-- note: correct format is 'yyyy-mm-dd'
-- note: the folling query will detect empty strings, but not nulls
SELECT
	EXISTS(
		SELECT 1
        FROM users_staging
        WHERE signup_date NOT REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
    ) AS has_incorrect_format;
    
-- check for any inconsistencies, misspellings, empty strings, or nulls in the region column
SELECT DISTINCT region
FROM users_staging;

-- check for any inconsistencies, misspellings, empty strings, or nulls in the device column
SELECT DISTINCT device
FROM users_staging;

-- check for any inconsistencies, misspellings, empty strings, or nulls in the platform column
SELECT DISTINCT platform
FROM users_staging;

-- check for any inconsistencies, misspellings, empty strings, or nulls in the buyer_type column
SELECT DISTINCT buyer_type
FROM users_staging;

-- check for NULLS in the user_id columns
SELECT
	EXISTS(
		SELECT 1
        FROM users_staging
        WHERE user_id IS NULL
    ) AS has_nulls;

-- check for nulls in the signup_date column
SELECT
	EXISTS(
		SELECT 1
        FROM users_staging
        WHERE signup_date IS NULL
    ) AS has_nulls;
    
-- check for invalid values in the signup_date column such as 9999-99-99
-- note: "STR_TO_DATE(signup_date, '%Y-%m-%d')" will return null for an invalid date like 9999-99-99
SELECT signup_date
FROM users_staging
WHERE STR_TO_DATE(signup_date, '%Y-%m-%d') IS NULL;

-- Step 4. Address Missing Values

-- no missing values to address

-- Step 5. Convert Columns to Appropriate Data Types

-- convert signup_date column to date data type
ALTER TABLE users_staging
MODIFY signup_date DATE;

-- Step 6. Look at Summary Stastics for Numerical Columns

-- no numerical columns to run summary statistics on

-- Step 7. Validate Logical Relationships Between Columns

-- no logical relationships between columns to check