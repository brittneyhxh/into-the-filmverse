-- Run once. Raw tables mirror the Kaggle CSV columns almost exactly, with
-- everything typed as STRING. This dataset is messy (budget/revenue have
-- non-numeric junk values, genres/production_companies are stringified
-- Python lists rather than clean JSON) so we land it as-is and do all
-- cleaning/casting/parsing in the 03_transform step, not here.

USE DATABASE FILM_ANALYTICS;
USE SCHEMA RAW;

CREATE OR REPLACE TABLE FILM_ANALYTICS.RAW.MOVIES_METADATA_RAW (
    adult                   STRING,
    belongs_to_collection   STRING,
    budget                  STRING,
    genres                  STRING,
    homepage                STRING,
    id                      STRING,
    imdb_id                 STRING,
    original_language       STRING,
    original_title          STRING,
    overview                STRING,
    popularity              STRING,
    poster_path             STRING,
    production_companies    STRING,
    production_countries    STRING,
    release_date            STRING,
    revenue                 STRING,
    runtime                 STRING,
    spoken_languages        STRING,
    status                  STRING,
    tagline                 STRING,
    title                   STRING,
    video                   STRING,
    vote_average            STRING,
    vote_count              STRING
);

CREATE OR REPLACE TABLE FILM_ANALYTICS.RAW.CREDITS_RAW (
    cast_json   STRING,   -- CSV column is named "cast" (reserved word) - renamed
    crew_json   STRING,   -- CSV column is named "crew"
    id          STRING
);
