-- Cleans MOVIES_METADATA_RAW into typed columns and parses the two
-- JSON-like fields (genres, production_companies) into VARIANT arrays.
--
-- The raw genres/production_companies columns look like Python dict repr,
-- e.g.  "[{'id': 16, 'name': 'Animation'}, {'id': 35, 'name': 'Comedy'}]"
-- which is NOT valid JSON (single quotes). We fix that with a blanket
-- REPLACE of ' -> " before PARSE_JSON. This is a known simplification:
-- if a company or genre name itself contains an apostrophe, that row's
-- parse will fail - we use TRY_PARSE_JSON so those rows just get a NULL
-- array instead of erroring out the whole transform, and we surface a
-- count of affected rows below so you know the scale of the issue.

USE DATABASE FILM_ANALYTICS;
USE SCHEMA ANALYTICS;
USE WAREHOUSE FILM_ANALYTICS_WH;

CREATE OR REPLACE TABLE FILM_ANALYTICS.ANALYTICS.STG_MOVIES AS
SELECT
    TRY_CAST(id AS NUMBER)                     AS movie_id,
    title,
    original_title,
    TRY_CAST(budget AS NUMBER)                 AS budget,
    TRY_CAST(revenue AS NUMBER)                AS revenue,
    TRY_CAST(release_date AS DATE)             AS release_date,
    TRY_CAST(runtime AS NUMBER)                AS runtime,
    TRY_CAST(popularity AS FLOAT)              AS popularity,
    TRY_CAST(vote_average AS FLOAT)            AS vote_average,
    TRY_CAST(vote_count AS NUMBER)             AS vote_count,
    original_language,
    status,
    TRY_PARSE_JSON(REPLACE(genres, '''', '"'))               AS genres_variant,
    TRY_PARSE_JSON(REPLACE(production_companies, '''', '"')) AS studios_variant
FROM FILM_ANALYTICS.RAW.MOVIES_METADATA_RAW
WHERE TRY_CAST(id AS NUMBER) IS NOT NULL;   -- drop the handful of corrupted rows with a non-numeric id

-- How many rows failed to parse genres/studios (apostrophe-in-name issue)?
-- Useful to check once, not part of the pipeline logic itself.
SELECT
    COUNT_IF(genres IS NOT NULL AND genres != '[]' AND genres_variant IS NULL)  AS genre_parse_failures,
    COUNT_IF(studios IS NOT NULL AND studios != '[]' AND studios_variant IS NULL) AS studio_parse_failures
FROM (
    SELECT
        r.genres,
        s.genres_variant,
        r.production_companies AS studios,
        s.studios_variant
    FROM FILM_ANALYTICS.RAW.MOVIES_METADATA_RAW r
    JOIN FILM_ANALYTICS.ANALYTICS.STG_MOVIES s
      ON TRY_CAST(r.id AS NUMBER) = s.movie_id
);
