-- =====================================================
-- LAYOFFS DATA CLEANING (MySQL 8)
-- Input: table `layoffs`, imported from layoffs.csv with MySQL Workbench's Table Data Import Wizard
-- Steps: 1) staging copy  2) remove duplicates  3) standardize values
--        4) convert the date column  5) fill in blanks  6) drop the helper column
-- =====================================================


-- 1. Work on a copy so the raw data stays untouched
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * FROM layoffs;


-- 2. Remove duplicates
-- First pass: number rows that share a few key columns (too few columns: flags rows that aren't true duplicates)
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, industry, total_laid_off, `date`) AS row_num
FROM layoffs_staging;

-- Second pass: a row is only a duplicate if every column matches
WITH duplicate_cte AS
(
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off, `date`,
                            stage, country, funds_raised_millions) AS row_num
    FROM layoffs_staging
)
SELECT * FROM duplicate_cte
WHERE row_num > 1;

-- Spot-check one flagged company
SELECT * FROM layoffs_staging
WHERE company = 'Casper';

-- MySQL can't DELETE from a CTE, so copy the rows (with row_num) into a second staging table
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off, `date`,
                        stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SET SQL_SAFE_UPDATES = 0;
DELETE FROM layoffs_staging2
WHERE row_num > 1;
SET SQL_SAFE_UPDATES = 1;

SELECT * FROM layoffs_staging2;


-- 3. Standardize values
-- Company names: strip leading/trailing spaces
SELECT DISTINCT company, TRIM(company)
FROM layoffs_staging2;

SET SQL_SAFE_UPDATES = 0;
UPDATE layoffs_staging2
SET company = TRIM(company);
SET SQL_SAFE_UPDATES = 1;

-- Industry: 'Crypto', 'Crypto Currency' and 'CryptoCurrency' are the same category
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT * FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

SET SQL_SAFE_UPDATES = 0;
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
SET SQL_SAFE_UPDATES = 1;

-- Country: 'United States.' (trailing period) -> 'United States'
SELECT DISTINCT location
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2;

SET SQL_SAFE_UPDATES = 0;
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
SET SQL_SAFE_UPDATES = 1;


-- 4. Convert `date` from text (MM/DD/YYYY) to a real DATE column
SELECT `date`,
       STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

SET SQL_SAFE_UPDATES = 0;
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
SET SQL_SAFE_UPDATES = 1;

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- 5. Blanks and nulls
-- Rows with no layoff numbers at all
SELECT * FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Some companies have their industry filled in on one row but blank on another
SELECT * FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- Treat empty strings as NULL, then fill each missing industry from another row for the same company
SET SQL_SAFE_UPDATES = 0;
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;

SELECT * FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;


-- 6. Drop the helper column
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
