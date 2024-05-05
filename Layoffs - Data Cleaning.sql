-- Data Cleaing

SELECT * 
FROM layoffs;

-- 1. Remove Dupllicate
-- 2. Standardize the data
-- 3. Null Values or blank values
-- 4. Remove any Columns 

-- Creates similar table
CREATE TABLE layoffs_staging
LIKE layoffs;


SELECT * from layoffs_staging ;
-- inserted data into the table from original file
INSERT INTO layoffs_staging 
SELECT * FROM layoffs;

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, industry, total_laid_off,percentage_laid_off,`date`) AS row_num
FROM layoffs_staging ;


-- display the duplicate data
WITH duplicate_cte AS
(
	SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY company,location, industry, total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_num
	FROM layoffs_staging 
)
Select *  
FROM duplicate_cte
WHERE row_num>1;



-- inserted data into the table from layoff_stage 2
INSERT INTO layoffs_staging2 
	SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY company,location, industry, total_laid_off,percentage_laid_off,`date`,stage,country,funds_raised_millions) AS row_num
	FROM layoffs_staging ;

-- diplay
 SELECT * from layoffs_staging2
 WHERE row_num>1;


-- delete
 DELETE  from layoffs_staging2
 WHERE row_num>1;




-- Standadizing the data removed sapces
SELECT company , TRIM(company)
From layoffs_staging2;

UPDATE layoffs_staging2
set company= TRIM(company);



-- removing space and merging the data about crypto or crypto currency
SELECT  * 
From layoffs_staging2
where industry like "Crypto%";


UPDATE layoffs_staging2
set industry= "Crypto"
where industry like "Crypto%"
;

-- country haing dot after name in the country
SELECT  distinct country, TRIM(Trailing "." from country)
From layoffs_staging2 
order by 1;

UPDATE layoffs_staging2
set country = TRIM(Trailing "." from country)
where country like "United States%";


-- date to proper format
select `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
from layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

select `date`
from layoffs_staging2;

-- changing to data type of the table

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- WORKING WITH NULL AND BLANK VALUES 

SELECT * 
from layoffs_staging2
where total_laid_off is null
and percentage_laid_off is null;

select * 
from layoffs_staging2
where industry is null
or industry ="";




select * from layoffs_staging2
where company="Airbnb";

-- updateing from blanks to null
UPDATE layoffs_staging2
SET industry=null
where industry="";

-- lookign fo nulls

SELECT t1.company , t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company=t2.company
    AND t1.location=t2.location
WHERE t1.industry is null
and t2.industry is not null ;

	

Update layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company=t2.company
set t1.industry=t2.industry    
WHERE t1.industry is null
and t2.industry is not null ;



select * from layoffs_staging2
where industry is null;


Alter table layoffs_staging2
drop column row_num;




select * from layoffs_staging2



