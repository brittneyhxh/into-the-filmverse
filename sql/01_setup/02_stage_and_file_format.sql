-- Run once. Creates a CSV file format and an internal stage to upload
-- the Kaggle CSVs into, ahead of COPY INTO loading them into raw tables.

USE DATABASE FILM_ANALYTICS;
USE SCHEMA RAW;

CREATE OR REPLACE FILE FORMAT FILM_ANALYTICS.RAW.CSV_FORMAT
  TYPE = CSV
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  SKIP_HEADER = 1
  NULL_IF = ('', 'NaN', 'null', 'NULL')
  EMPTY_FIELD_AS_NULL = TRUE
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

CREATE OR REPLACE STAGE FILM_ANALYTICS.RAW.MOVIE_DATA_STAGE
  FILE_FORMAT = FILM_ANALYTICS.RAW.CSV_FORMAT
  COMMENT = 'Landing zone for movies_metadata.csv and credits.csv before loading';

-- After running this, upload the two CSVs to the stage. Easiest path is
-- Snowsight: Data > Databases > FILM_ANALYTICS > RAW > Stages >
-- MOVIE_DATA_STAGE > "+ Files" button, and upload both CSVs there.
--
-- Or via SnowSQL / Snowflake CLI from your machine:
--   PUT file://movies_metadata.csv @FILM_ANALYTICS.RAW.MOVIE_DATA_STAGE AUTO_COMPRESS=TRUE;
--   PUT file://credits.csv         @FILM_ANALYTICS.RAW.MOVIE_DATA_STAGE AUTO_COMPRESS=TRUE;

-- Sanity check after uploading:
-- LIST @FILM_ANALYTICS.RAW.MOVIE_DATA_STAGE;
