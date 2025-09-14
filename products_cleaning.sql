-- Cleaning Products Dataset

-- Step 1. Take a Look at the Dataset

-- look at the columns of the dataset and their datatypes
DESCRIBE social_commerece_marketplace.products;

-- look at the first 10 rows of the dataset
SELECT *
FROM products
LIMIT 10;

-- Step 2. Remove Duplicates

-- create staging table and remove duplicates
CREATE TABLE products_staging AS
SELECT DISTINCT *
FROM products;

SELECT *
FROM products_staging
LIMIT 10;

-- Step 3. Standardize, Check for Inconsistencies, and Check for Missing Values

-- reomve leading and trailing whitespace in text columns
UPDATE products_staging
SET product_id = TRIM(product_id);

UPDATE products_staging
SET category = TRIM(category);

UPDATE products_staging
SET subcategory = TRIM(subcategory);

UPDATE products_staging
SET brand = TRIM(brand);

-- check if there are inconsistencies or misspellings in the category column
SELECT DISTINCT category
FROM products_staging;

-- check if there are inconsistencies or misspellings in the subcategory column
SELECT DISTINCT subcategory
FROM products_staging;

-- check if there are inconsistencies or misspellings in the brand column
SELECT DISTINCT brand
FROM products_staging;

-- check if there are NULLS in the product_id column
SELECT 
  EXISTS (
    SELECT 1 
    FROM products 
    WHERE product_id IS NULL
  ) AS has_nulls;
  
-- check if there are NULLS in the category column
SELECT
	EXISTS (
		SELECT 1
		FROM products_staging
		WHERE category IS NULL
	) AS has_nulls;
    
-- check if there are NULLS in the subcategory column
SELECT
	EXISTS(
		SELECT 1
        FROM products_staging
        WHERE subcategory IS NULL
    ) AS has_nulls;

-- check if there are NULLS in the brand column
SELECT
	EXISTS(
		SELECT 1
        FROM products_staging
        WHERE brand IS NULL
    ) AS has_nulls;
    
-- check if there are NULLS in the price category
SELECT
	EXISTS(
		SELECT 1
        FROM products_staging
        WHERE price IS NULL
    ) AS has_nulls;

-- check if there are any blanks in the product_id column
SELECT
	EXISTS(
		SELECT 1
        FROM products_staging
        WHERE product_id = ''
    ) AS has_blanks;
    
-- check if there are any blanks in the category column
SELECT
	EXISTS(
		SELECT 1
		FROM products_staging
		WHERE category = ''
	) AS has_blanks;
    
-- check if there are any blanks in the subcategory column
SELECT
	EXISTS(
		SELECT 1
        FROM products_staging
        WHERE subcategory = ''
    ) AS has_blanks;
    
-- check if there are any blanks in the brand column
SELECT
	EXISTS(
		SELECT 1
        FROM products_staging
        WHERE brand = ''
    ) AS has_blanks;
    
-- check if there are any product ids that are in the correct format
SELECT
	EXISTS(
		SELECT 1
        FROM products_staging
        WHERE product_id NOT REGEXP '^P[0-9]{5}$'
    ) AS has_invalid_format;
    
-- check if there are any values that are less than or equal to 0 in the price column
SELECT
	EXISTS(
		SELECT 1
        FROM products_staging
        WHERE price <= 0
    ) AS has_invalid_values;

-- Step 4. Handle Rows with Nulls, Blanks, or Invalid Entries

-- no NULLS, blanks, or invalid entries to address

-- Step 5. Convert Tables To Appropriate Data Types

-- all columns are already of the appropriate data types

-- Step 6. Look at Summary Statistics of Numerical Colummns

-- summary statistics of price column
SELECT
	MIN(price),
    MAX(price),
    AVG(price),
    STDDEV(price)
FROM
	products_staging;

-- Step 7. Validate Logical Relationships Bewtween Columns

-- logical relationships between columns are already valid