# Building the star schema

Run in order on Snowsight (`sql/02_load/`):

1. `01_stg_movies.sql` - casts raw string columns to real types, parses
   the genres/production_companies JSON-like fields into VARIANT arrays.
   Prints a count of rows where that parse failed (apostrophes in names
   break the naive quote-replacement - expect this to be small, not zero).
2. `02_dim_genre.sql` - distinct genres, flattened out of the array column.
3. `03_dim_studio.sql` - distinct studios/production companies, same idea.
4. `04_dim_release_date.sql` - one row per distinct release date, with
   year/quarter/month/decade and summer/holiday-release flags for the
   seasonal-release-pattern visual.
5. `05_bridge_tables.sql` - BRIDGE_MOVIE_GENRE and BRIDGE_MOVIE_STUDIO.
   A movie has many genres and many studios, so those relationships can't
   be single foreign keys on the fact table - this is the standard star-
   schema fix (associative/bridge tables).
6. `06_fact_box_office.sql` - one row per movie: budget, revenue, computed
   profit/ROI, popularity, vote average/count, runtime. Includes a
   `has_valid_financials` flag (see note below) and prints row counts.

## Final schema shape

```
DIM_GENRE (genre_id, genre_name)
DIM_STUDIO (studio_id, studio_name)
DIM_RELEASE_DATE (date_key, year, quarter, month, decade, is_summer_release, is_holiday_release)

BRIDGE_MOVIE_GENRE (movie_id, genre_id)
BRIDGE_MOVIE_STUDIO (movie_id, studio_id)

FACT_BOX_OFFICE (movie_id, title, date_key, budget, revenue, profit, roi,
                  has_valid_financials, runtime, popularity, vote_average,
                  vote_count, original_language, status)
```

`FACT_BOX_OFFICE.date_key` joins to `DIM_RELEASE_DATE.date_key`.
`BRIDGE_MOVIE_GENRE`/`BRIDGE_MOVIE_STUDIO` join `FACT_BOX_OFFICE.movie_id`
to the respective dim's id column - go through the bridge, not a direct FK,
since genre and studio are many-to-many with movies.

## Why `has_valid_financials` matters

A large chunk of this dataset has `budget = 0` or `revenue = 0`, which
means "not reported" rather than "made $0." Any ROI or profit chart needs
to filter `WHERE has_valid_financials` or the unreported rows will
dominate/distort the numbers (e.g. "movies with $0 budget" would otherwise
show as infinite ROI). Revenue-trend-by-year charts that don't compute
ratios are fine without the filter, since a $0 doesn't corrupt a sum in
the same misleading way - though excluding it will still smooth the trend.

## Sanity-check query

```sql
SELECT
    g.genre_name,
    COUNT(*)                         AS movie_count,
    SUM(f.revenue)                   AS total_revenue,
    AVG(f.roi)                       AS avg_roi
FROM FILM_ANALYTICS.ANALYTICS.FACT_BOX_OFFICE f
JOIN FILM_ANALYTICS.ANALYTICS.BRIDGE_MOVIE_GENRE bg ON f.movie_id = bg.movie_id
JOIN FILM_ANALYTICS.ANALYTICS.DIM_GENRE g ON bg.genre_id = g.genre_id
WHERE f.has_valid_financials
GROUP BY g.genre_name
ORDER BY total_revenue DESC;
```
