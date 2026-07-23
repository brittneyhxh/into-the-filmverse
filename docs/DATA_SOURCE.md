# Data source

**Dataset:** The Movies Dataset (Kaggle)
**URL:** https://www.kaggle.com/datasets/rounakbanik/the-movies-dataset
**License:** CC0 1.0 (public domain) - metadata originally sourced from
TMDB and GroupLens/MovieLens.

## Files used

- `movies_metadata.csv` - budget, revenue, genres, release_date, production
  companies, vote_average, runtime, ~45,000 rows
- `credits.csv` - cast/crew, joinable on movie id (optional, for a later
  "top directors/actors by box office" feature)

## Notes

- `genres` and `production_companies` columns are stored as stringified
  Python lists/dicts in the raw CSV - these need to be parsed/flattened
  during the transform step, not treated as plain strings.
- `budget` and `revenue` contain a lot of 0 values (unreported, not actually
  zero) - these should be filtered out of ROI calculations rather than
  treated as real data points.
- Not affiliated with or endorsed by Kaggle, TMDB, or GroupLens; used here
  for a personal/educational portfolio project only.
