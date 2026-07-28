-- Run after the CSVs have been uploaded to MOVIE_DATA_STAGE (see
-- 01_setup/02_stage_and_file_format.sql for upload instructions).

USE DATABASE FILM_ANALYTICS;
USE SCHEMA RAW;
USE WAREHOUSE FILM_ANALYTICS_WH;

COPY INTO FILM_ANALYTICS.RAW.MOVIES_METADATA_RAW
  FROM @FILM_ANALYTICS.RAW.MOVIE_DATA_STAGE/movies_metadata.csv.gz
  FILE_FORMAT = (FORMAT_NAME = FILM_ANALYTICS.RAW.CSV_FORMAT)
  ON_ERROR = 'CONTINUE';   -- skip malformed rows rather than aborting the whole load

COPY INTO FILM_ANALYTICS.RAW.CREDITS_RAW
  FROM @FILM_ANALYTICS.RAW.MOVIE_DATA_STAGE/credits.csv.gz
  FILE_FORMAT = (FORMAT_NAME = FILM_ANALYTICS.RAW.CSV_FORMAT)
  ON_ERROR = 'CONTINUE';

-- Note: if you uploaded without AUTO_COMPRESS (e.g. via Snowsight drag-and-
-- drop), the staged filenames won't have the .gz suffix - check with
-- LIST @FILM_ANALYTICS.RAW.MOVIE_DATA_STAGE; and adjust the FROM path above
-- to match the actual filename shown.

-- Sanity checks after loading:
SELECT COUNT(*) AS row_count FROM FILM_ANALYTICS.RAW.MOVIES_METADATA_RAW;
SELECT COUNT(*) AS row_count FROM FILM_ANALYTICS.RAW.CREDITS_RAW;
SELECT * FROM FILM_ANALYTICS.RAW.MOVIES_METADATA_RAW LIMIT 10;

-- Check how many rows had load errors (helps gauge data quality issues):
SELECT * FROM TABLE(VALIDATE(FILM_ANALYTICS.RAW.MOVIES_METADATA_RAW, JOB_ID => '_last'));
