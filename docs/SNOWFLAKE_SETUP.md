# One-time Snowflake setup

Run these once, in order, from a worksheet in Snowsight (role: ACCOUNTADMIN or
SYSADMIN with sufficient privileges).

## 1. Database, warehouse, schema

```sql
CREATE DATABASE IF NOT EXISTS FILM_ANALYTICS;
CREATE SCHEMA IF NOT EXISTS FILM_ANALYTICS.RAW;
CREATE SCHEMA IF NOT EXISTS FILM_ANALYTICS.ANALYTICS;

CREATE WAREHOUSE IF NOT EXISTS FILM_ANALYTICS_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60          -- suspend after 60s idle to protect trial credits
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;
```

## 2. GitHub API integration

Replace `<github-username>` with your actual GitHub username or org.

```sql
CREATE OR REPLACE API INTEGRATION film_analytics_git_api
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/<github-username>')
  ENABLED = TRUE;
```

If the repo is private, you'll also need a secret holding a GitHub personal
access token, referenced by the git repository object below:

```sql
CREATE OR REPLACE SECRET film_analytics_git_secret
  TYPE = password
  USERNAME = '<github-username>'
  PASSWORD = '<github-personal-access-token>';
```

(Skip the secret if the repo is public.)

## 3. Git repository object

```sql
CREATE OR REPLACE GIT REPOSITORY FILM_ANALYTICS.RAW.FILM_ANALYTICS_REPO
  API_INTEGRATION = film_analytics_git_api
  ORIGIN = 'https://github.com/<github-username>/film-analytics.git'
  -- GIT_CREDENTIALS = film_analytics_git_secret   -- uncomment if private repo
  ;

-- Pull the latest commits down into Snowflake
ALTER GIT REPOSITORY FILM_ANALYTICS.RAW.FILM_ANALYTICS_REPO FETCH;

-- Sanity check: list files Snowflake can see from the repo
LS @FILM_ANALYTICS.RAW.FILM_ANALYTICS_REPO/branches/main;
```

## 4. Create the Streamlit app pointing at the git repo

```sql
CREATE OR REPLACE STREAMLIT FILM_ANALYTICS.ANALYTICS.FILM_ANALYTICS_APP
  ROOT_LOCATION = '@FILM_ANALYTICS.RAW.FILM_ANALYTICS_REPO/branches/main/streamlit'
  MAIN_FILE = 'streamlit_app.py'
  QUERY_WAREHOUSE = FILM_ANALYTICS_WH;
```

After this, the app shows up in Snowsight under Projects > Streamlit.

## 5. Refreshing after new commits

Whenever you push changes to GitHub, Snowflake's copy is a snapshot until you
refresh it:

```sql
ALTER GIT REPOSITORY FILM_ANALYTICS.RAW.FILM_ANALYTICS_REPO FETCH;
```

This can be automated later with a GitHub Action that runs `snow git fetch`
via the Snowflake CLI, but for a small solo project it's fine to just run
this manually before you demo or record it.

## Internal stage for raw data uploads (separate from the git repo)

The CSV dataset itself should NOT go through git (too large, and .gitignore
excludes it). It gets uploaded directly to a Snowflake stage instead:

```sql
CREATE OR REPLACE STAGE FILM_ANALYTICS.RAW.MOVIE_DATA_STAGE
  FILE_FORMAT = (TYPE = CSV FIELD_OPTIONALLY_ENCLOSED_BY = '"' SKIP_HEADER = 1);
```

Upload via SnowSQL, the Snowflake CLI (`snow stage copy`), or the Snowsight
"Upload files to stage" UI. Covered in the next step once the dataset is
downloaded.
