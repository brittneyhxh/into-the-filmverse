-- Grain: one row per movie. Genre/studio are many-to-many so they're NOT
-- foreign keys here - join through BRIDGE_MOVIE_GENRE / BRIDGE_MOVIE_STUDIO
-- when you need to slice by genre or studio.
--
-- budget/revenue of 0 in this dataset means "unreported", not "actually
-- zero" - has_valid_financials flags rows where both are > 0, so ROI/profit
-- visuals can filter on it instead of getting skewed by unreported movies.

USE DATABASE FILM_ANALYTICS;
USE SCHEMA ANALYTICS;

CREATE OR REPLACE TABLE FILM_ANALYTICS.ANALYTICS.FACT_BOX_OFFICE AS
SELECT
    movie_id,
    title,
    release_date                                             AS date_key,
    budget,
    revenue,
    CASE WHEN budget > 0 AND revenue > 0 THEN revenue - budget END       AS profit,
    CASE WHEN budget > 0 AND revenue > 0 THEN (revenue - budget) / budget END AS roi,
    (budget > 0 AND revenue > 0)                             AS has_valid_financials,
    runtime,
    popularity,
    vote_average,
    vote_count,
    original_language,
    status
FROM FILM_ANALYTICS.ANALYTICS.STG_MOVIES;

-- Sanity checks
SELECT COUNT(*) AS total_movies FROM FILM_ANALYTICS.ANALYTICS.FACT_BOX_OFFICE;
SELECT COUNT(*) AS movies_with_valid_financials
FROM FILM_ANALYTICS.ANALYTICS.FACT_BOX_OFFICE
WHERE has_valid_financials;
