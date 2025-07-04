# SQL Data Cleaning: Layoffs Analysis

This repository contains SQL scripts for cleaning and preparing a dataset related to company layoffs. The goal is to transform raw layoff data into a clean, standardized, and usable format for further analysis.


## Project Overview

The `layoffs` dataset contains information about layoffs from various companies. Before any meaningful analysis can be performed, the data needs to be thoroughly cleaned. This involves:

  * Identifying and removing duplicate entries.
  * Standardizing text fields (e.g., company names, industries, countries) to ensure consistency.
  * Addressing missing or blank values by either populating them or deciding on an appropriate handling strategy.
  * Removing any columns that are not relevant for the analysis.

## Data Cleaning Steps

The cleaning process is performed on a staging table to preserve the original dataset.

### Initial Setup

```sql
-- Creates a similar table named layoffs_staging
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Inserts data from the original 'layoffs' table into 'layoffs_staging'
INSERT INTO layoffs_staging
SELECT * FROM layoffs;
```

### 1\. Remove Duplicates

Duplicate rows can skew analysis. A `row_num` is generated using a window function to identify and remove these duplicates.

```sql
-- Identifies duplicates by partitioning on key columns
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

-- Creates a second staging table to facilitate deletion of duplicates
CREATE TABLE layoffs_staging2
	SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY company,location, industry, total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_num
	FROM layoffs_staging;

-- Displays identified duplicate rows
SELECT * from layoffs_staging2
WHERE row_num > 1;

-- Deletes duplicate rows from layoffs_staging2
DELETE FROM layoffs_staging2
WHERE row_num > 1;
```

### 2\. Standardize Data

This step focuses on ensuring consistency in text fields and proper date formatting.

  * **Trimming Whitespace from Company Names:**

    ```sql
    SELECT company, TRIM(company)
    FROM layoffs_staging2;

    UPDATE layoffs_staging2
    SET company = TRIM(company);
    ```

  * **Consolidating Industry Categories (e.g., 'Crypto' variations):**

    ```sql
    SELECT *
    FROM layoffs_staging2
    WHERE industry LIKE "Crypto%";

    UPDATE layoffs_staging2
    SET industry = "Crypto"
    WHERE industry LIKE "Crypto%";
    ```

  * **Cleaning Country Names (e.g., removing trailing periods):**

    ```sql
    SELECT DISTINCT country, TRIM(TRAILING "." FROM country)
    FROM layoffs_staging2
    ORDER BY 1;

    UPDATE layoffs_staging2
    SET country = TRIM(TRAILING "." FROM country)
    WHERE country LIKE "United States%";
    ```

  * **Converting Date Format and Data Type:**

    ```sql
    SELECT `date`,
    STR_TO_DATE(`date`, '%m/%d/%Y')
    FROM layoffs_staging2;

    UPDATE layoffs_staging2
    SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

    ALTER TABLE layoffs_staging2
    MODIFY COLUMN `date` DATE;
    ```

### 3\. Handle Null and Blank Values

Missing data is addressed by identifying nulls/blanks and, where appropriate, populating them based on existing information.

  * **Identifying Null/Blank Values for `total_laid_off` and `percentage_laid_off`:**

    ```sql
    SELECT *
    FROM layoffs_staging2
    WHERE total_laid_off IS NULL
    AND percentage_laid_off IS NULL;
    ```

  * **Updating Blank `industry` values to `NULL`:**

    ```sql
    SELECT *
    FROM layoffs_staging2
    WHERE industry IS NULL
    OR industry = "";

    UPDATE layoffs_staging2
    SET industry = NULL
    WHERE industry = "";
    ```

  * **Populating Null `industry` values based on Company:**

    If a company has a non-null industry in another row, that industry is used to fill the null.

    ```sql
    SELECT t1.company, t1.industry, t2.industry
    FROM layoffs_staging2 t1
    JOIN layoffs_staging2 t2
    	ON t1.company = t2.company
    	AND t1.location = t2.location
    WHERE t1.industry IS NULL
    AND t2.industry IS NOT NULL;

    UPDATE layoffs_staging2 t1
    JOIN layoffs_staging2 t2
    	ON t1.company = t2.company
    SET t1.industry = t2.industry
    WHERE t1.industry IS NULL
    AND t2.industry IS NOT NULL;

    SELECT *
    FROM layoffs_staging2
    WHERE industry IS NULL;
    ```

### 4\. Remove Unnecessary Columns

The temporary `row_num` column, used for duplicate detection, is no longer needed.

```sql
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
```

## Explore the Data

After cleaning, the `layoffs_staging2` table is ready for exploration and further analysis.

```sql
SELECT * FROM layoffs_staging2;
```

## How to Use

1.  **Import your data:** Ensure your original layoff data is loaded into a table named `layoffs` in your MySQL/SQL database.
2.  **Execute the script:** Run the provided SQL queries sequentially in your database management tool. Each section builds upon the previous one.
3.  **Analyze `layoffs_staging2`:** The `layoffs_staging2` table will contain your cleaned and standardized layoff data.

-----
