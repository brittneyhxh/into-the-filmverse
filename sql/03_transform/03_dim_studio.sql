-- Flattens studios_variant (an array of {id, name} objects per movie) into
-- one row per distinct production company/studio.

USE DATABASE FILM_ANALYTICS;
USE SCHEMA ANALYTICS;

CREATE OR REPLACE TABLE FILM_ANALYTICS.ANALYTICS.DIM_STUDIO AS
SELECT DISTINCT
    f.value:id::NUMBER   AS studio_id,
    f.value:name::STRING AS studio_name
FROM FILM_ANALYTICS.ANALYTICS.STG_MOVIES m,
     LATERAL FLATTEN(input => m.studios_variant) f
WHERE f.value:id IS NOT NULL
ORDER BY studio_id;
