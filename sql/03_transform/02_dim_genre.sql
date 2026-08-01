-- Flattens genres_variant (an array of {id, name} objects per movie) into
-- one row per distinct genre.

USE DATABASE FILM_ANALYTICS;
USE SCHEMA ANALYTICS;

CREATE OR REPLACE TABLE FILM_ANALYTICS.ANALYTICS.DIM_GENRE AS
SELECT DISTINCT
    f.value:id::NUMBER   AS genre_id,
    f.value:name::STRING AS genre_name
FROM FILM_ANALYTICS.ANALYTICS.STG_MOVIES m,
     LATERAL FLATTEN(input => m.genres_variant) f
WHERE f.value:id IS NOT NULL
ORDER BY genre_id;
