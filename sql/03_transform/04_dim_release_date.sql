-- One row per distinct release date actually present in the data, with
-- calendar attributes for slicing (year, quarter, decade, season flag).
-- Using the date itself as the key rather than a surrogate int - keeps
-- the fact table join simple and is fine at this data volume.

USE DATABASE FILM_ANALYTICS;
USE SCHEMA ANALYTICS;

CREATE OR REPLACE TABLE FILM_ANALYTICS.ANALYTICS.DIM_RELEASE_DATE AS
SELECT DISTINCT
    release_date                                   AS date_key,
    YEAR(release_date)                             AS year,
    QUARTER(release_date)                          AS quarter,
    MONTH(release_date)                            AS month,
    MONTHNAME(release_date)                        AS month_name,
    DAYNAME(release_date)                          AS day_name,
    (YEAR(release_date) / 10)::INT * 10            AS decade,
    CASE
        WHEN MONTH(release_date) IN (6, 7, 8) THEN TRUE
        ELSE FALSE
    END                                             AS is_summer_release,
    CASE
        WHEN MONTH(release_date) IN (11, 12) THEN TRUE
        ELSE FALSE
    END                                             AS is_holiday_release
FROM FILM_ANALYTICS.ANALYTICS.STG_MOVIES
WHERE release_date IS NOT NULL;
