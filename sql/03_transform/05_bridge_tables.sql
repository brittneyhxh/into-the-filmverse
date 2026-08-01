-- A movie can have multiple genres and multiple studios, so those
-- relationships can't live as single foreign keys on the fact table.
-- Standard star-schema pattern: bridge (associative) tables.

USE DATABASE FILM_ANALYTICS;
USE SCHEMA ANALYTICS;

CREATE OR REPLACE TABLE FILM_ANALYTICS.ANALYTICS.BRIDGE_MOVIE_GENRE AS
SELECT DISTINCT
    m.movie_id,
    f.value:id::NUMBER AS genre_id
FROM FILM_ANALYTICS.ANALYTICS.STG_MOVIES m,
     LATERAL FLATTEN(input => m.genres_variant) f
WHERE f.value:id IS NOT NULL;

CREATE OR REPLACE TABLE FILM_ANALYTICS.ANALYTICS.BRIDGE_MOVIE_STUDIO AS
SELECT DISTINCT
    m.movie_id,
    f.value:id::NUMBER AS studio_id
FROM FILM_ANALYTICS.ANALYTICS.STG_MOVIES m,
     LATERAL FLATTEN(input => m.studios_variant) f
WHERE f.value:id IS NOT NULL;
