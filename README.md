# Tech Layoffs 2020–2023: SQL Data Cleaning & Exploratory Analysis

Cleaned and analyzed 2,361 layoff events (March 2020 – March 2023; 1,893 companies in 60 countries) using MySQL.

## Data cleaning ([data_cleaning.sql](data_cleaning.sql))

1. **Staging copy:** all work happens on a copy, so the raw table is never modified.
2. **Duplicates:** flagged rows that match on every column with `ROW_NUMBER() OVER (PARTITION BY ...)`. MySQL can't delete from a CTE, so rows were copied with their row number into a second staging table and the duplicates deleted there.
3. **Standardization:**
   - trimmed stray spaces from company names
   - merged "Crypto", "Crypto Currency" and "CryptoCurrency" into one industry
   - fixed "United States." (with a trailing period) in the country column
4. **Dates:** converted text dates (`MM/DD/YYYY`) to a real `DATE` column with `STR_TO_DATE()` and `ALTER TABLE`.
5. **Missing values:** turned blank industries into `NULL`, then filled them from another row for the same company with a self-join `UPDATE`.
6. **Cleanup:** dropped the helper column.

## Exploratory analysis ([exploratory_analysis.sql](exploratory_analysis.sql))

- The largest layoffs, and companies that laid off 100% of staff, ranked by funds raised
- Total layoffs by funding stage (Seed through Post-IPO)
- Monthly layoffs with a running total (`SUM() OVER (ORDER BY month)`)
- Top 5 companies by layoffs in each year (`DENSE_RANK() OVER (PARTITION BY year ...)`)

## SQL techniques

CTEs · window functions (`ROW_NUMBER`, `DENSE_RANK`, `SUM() OVER`) · self-join `UPDATE` · `TRIM`, `STR_TO_DATE`, `SUBSTRING` · `ALTER TABLE` · staging tables and `SQL_SAFE_UPDATES` for safe deletes and updates

## Run it yourself

1. In MySQL 8, create a schema: `CREATE DATABASE world_layoffs;`
2. Import [layoffs.csv](layoffs.csv) into a table named `layoffs` (MySQL Workbench: right-click the schema, then **Table Data Import Wizard**).
3. Run `data_cleaning.sql`, then `exploratory_analysis.sql`.

## Data

`layoffs.csv` holds layoff events tracked by [layoffs.fyi](https://layoffs.fyi), as published on Kaggle ([Layoffs 2022](https://www.kaggle.com/datasets/swaptr/layoffs-2022)).
Columns: company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions.

This project follows the data-cleaning workflow from Alex The Analyst's MySQL portfolio project.
