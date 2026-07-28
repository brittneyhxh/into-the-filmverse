# Loading the data: step by step

## 1. Download the dataset from Kaggle

- Go to https://www.kaggle.com/datasets/rounakbanik/the-movies-dataset
- You'll need a free Kaggle account to download (click "Download" - it may
  prompt you to sign in first)
- This downloads a zip containing several CSVs - you only need two:
  - `movies_metadata.csv`
  - `credits.csv`
  (You can delete/ignore `keywords.csv`, `links.csv`, `links_small.csv`,
  `ratings.csv`, `ratings_small.csv` - not used in this project.)

## 2. Run the setup SQL

In Snowsight, open a new worksheet and run, in order:
1. `sql/01_setup/01_database_warehouse.sql`
2. `sql/01_setup/02_stage_and_file_format.sql`
3. `sql/02_load/01_raw_tables.sql`

## 3. Upload the CSVs to the stage

Easiest path - Snowsight UI:
1. Data > Databases > FILM_ANALYTICS > RAW > Stages > MOVIE_DATA_STAGE
2. Click "+ Files" in the top right
3. Upload `movies_metadata.csv` and `credits.csv`

Alternative - Snowflake CLI, from your machine where the files downloaded:
```
snow stage copy movies_metadata.csv @FILM_ANALYTICS.RAW.MOVIE_DATA_STAGE --database FILM_ANALYTICS --schema RAW
snow stage copy credits.csv @FILM_ANALYTICS.RAW.MOVIE_DATA_STAGE --database FILM_ANALYTICS --schema RAW
```

Either way, confirm the upload worked:
```sql
LIST @FILM_ANALYTICS.RAW.MOVIE_DATA_STAGE;
```

## 4. Check the staged filenames match the COPY INTO script

The Snowsight UI upload does NOT gzip the files, so they'll be staged as
`movies_metadata.csv` and `credits.csv` (no `.gz`). The CLI/SnowSQL `PUT`
command with `AUTO_COMPRESS=TRUE` *does* gzip them, staging them as
`movies_metadata.csv.gz` / `credits.csv.gz`.

`sql/02_load/02_copy_into.sql` assumes the `.gz` versions. If you uploaded
via Snowsight instead, edit that script to drop the `.gz` suffix from the
`FROM` paths before running it, or the COPY INTO will find no matching file.

## 5. Run the load

Run `sql/02_load/02_copy_into.sql`. Check the row counts and preview at the
bottom of that script - `movies_metadata.csv` should land ~45,000 rows and
`credits.csv` should land the same count (both are keyed by movie id).

## 6. Data quality heads-up for the next step (transform)

Don't clean this yet - just know going in that:
- `budget` and `revenue` are text columns containing a lot of `"0"` values
  (unreported, not actually free/worthless) and occasionally corrupted rows
  where columns got shifted
- `genres` and `production_companies` look like `[{'id': 35, 'name':
  'Comedy'}, ...]` - Python dict repr, not valid JSON (single quotes) - will
  need a `REPLACE` before `PARSE_JSON` can read them
- `release_date` is a plain date string, may have missing values

These get handled in `sql/03_transform/`, which we'll write next.
