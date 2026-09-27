-- =====================================================
-- LAYOFFS EXPLORATORY DATA ANALYSIS (MySQL 8)
-- Runs on the cleaned table from data_cleaning.sql: layoffs_staging2
-- =====================================================


-- Largest single layoff, and the highest share of a workforce laid off (1 = 100%)
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

-- Companies that laid off their entire workforce, biggest funding rounds first
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Total layoffs by company funding stage (Seed, Series A..., Post-IPO)
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- Total layoffs per month
SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off)
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC;

-- Rolling (cumulative) total of layoffs month by month
WITH rolling_total AS
(
    SELECT SUBSTRING(`date`, 1, 7) AS `MONTH`, SUM(total_laid_off) AS laid_off
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `MONTH`
    ORDER BY 1 ASC
)
SELECT `MONTH`, laid_off,
       SUM(laid_off) OVER (ORDER BY `MONTH`) AS rolling_total
FROM rolling_total;

-- Layoffs per company per year
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- Top 5 companies by layoffs in each year
WITH company_year (company, years, total_laid_off) AS
(
    SELECT company, YEAR(`date`), SUM(total_laid_off)
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
),
company_year_rank AS
(
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
    FROM company_year
    WHERE years IS NOT NULL
)
SELECT *
FROM company_year_rank
WHERE ranking <= 5;
