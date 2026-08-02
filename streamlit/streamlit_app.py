import streamlit as st
import pandas as pd
import plotly.express as px
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Film Analytics", layout="wide")
session = get_active_session()

# database/schema set-up
DB = "FILM_ANALYTICS"
SCHEMA = "ANALYTICS"

@st.cache_data(ttl=600)
def load_genres():
    return session.sql(f"SELECT genre_id, genre_name FROM {DB}.{SCHEMA}.DIM_GENRE ORDER BY genre_name").to_pandas()


@st.cache_data(ttl=600)
def load_year_bounds():
    row = session.sql(f"""
        SELECT MIN(YEAR(date_key)) AS min_year, MAX(YEAR(date_key)) AS max_year
        FROM {DB}.{SCHEMA}.DIM_RELEASE_DATE
    """).to_pandas().iloc[0]
    return int(row["MIN_YEAR"]), int(row["MAX_YEAR"])


@st.cache_data(ttl=600)
def load_top_studios(n=50):
    return session.sql(f"""
        SELECT s.studio_id, s.studio_name, COUNT(*) AS movie_count
        FROM {DB}.{SCHEMA}.BRIDGE_MOVIE_STUDIO bs
        JOIN {DB}.{SCHEMA}.DIM_STUDIO s ON bs.studio_id = s.studio_id
        GROUP BY s.studio_id, s.studio_name
        ORDER BY movie_count DESC
        LIMIT {n}
    """).to_pandas()


def build_filtered_movie_ids_cte(genre_ids, studio_ids, year_range):
    """Returns SQL for a CTE selecting movie_ids matching the active filters."""
    conditions = [
        "f.date_key IS NOT NULL",
        f"YEAR(f.date_key) BETWEEN {year_range[0]} AND {year_range[1]}",
    ]
    joins = ""
    if genre_ids:
        ids = ",".join(str(i) for i in genre_ids)
        joins += f" JOIN {DB}.{SCHEMA}.BRIDGE_MOVIE_GENRE bg ON f.movie_id = bg.movie_id AND bg.genre_id IN ({ids})"
    if studio_ids:
        ids = ",".join(str(i) for i in studio_ids)
        joins += f" JOIN {DB}.{SCHEMA}.BRIDGE_MOVIE_STUDIO bst ON f.movie_id = bst.movie_id AND bst.studio_id IN ({ids})"
    where = " AND ".join(conditions)
    return f"""
        SELECT DISTINCT f.movie_id
        FROM {DB}.{SCHEMA}.FACT_BOX_OFFICE f
        {joins}
        WHERE {where}
    """


# ---------- Sidebar filters ----------
st.sidebar.header("Filters")

genres_df = load_genres()
genre_labels = st.sidebar.multiselect(
    "Genre", options=genres_df["GENRE_NAME"].tolist(), default=[]
)
genre_ids = genres_df[genres_df["GENRE_NAME"].isin(genre_labels)]["GENRE_ID"].tolist()

min_year, max_year = load_year_bounds()
year_range = st.sidebar.slider("Release year", min_year, max_year, (min_year, max_year))

studios_df = load_top_studios()
studio_labels = st.sidebar.multiselect(
    "Studio (top 50 by movie count)", options=studios_df["STUDIO_NAME"].tolist(), default=[]
)
studio_ids = studios_df[studios_df["STUDIO_NAME"].isin(studio_labels)]["STUDIO_ID"].tolist()

movie_ids_cte = build_filtered_movie_ids_cte(genre_ids, studio_ids, year_range)

# ---------- Header + KPIs ----------
st.title("Film Analytics")
st.caption("Box office & industry trends — Snowflake + Streamlit")

kpi_df = session.sql(f"""
    WITH filtered_movies AS ({movie_ids_cte})
    SELECT
        COUNT(*) AS movie_count,
        SUM(f.revenue) AS total_revenue,
        AVG(CASE WHEN f.has_valid_financials THEN f.roi END) AS avg_roi
    FROM {DB}.{SCHEMA}.FACT_BOX_OFFICE f
    JOIN filtered_movies fm ON f.movie_id = fm.movie_id
""").to_pandas()

k1, k2, k3 = st.columns(3)
k1.metric("Movies", f"{int(kpi_df['MOVIE_COUNT'][0]):,}")
total_rev = kpi_df["TOTAL_REVENUE"][0]
k2.metric("Total revenue", f"${total_rev:,.0f}" if pd.notna(total_rev) else "—")
avg_roi = kpi_df["AVG_ROI"][0]
k3.metric("Avg ROI (valid financials only)", f"{avg_roi:.1%}" if pd.notna(avg_roi) else "—")

st.divider()

# ---------- Revenue & profit trend over time ----------
st.subheader("Revenue & profit by year")
trend_df = session.sql(f"""
    WITH filtered_movies AS ({movie_ids_cte})
    SELECT
        YEAR(f.date_key) AS year,
        SUM(f.revenue) AS total_revenue,
        SUM(CASE WHEN f.has_valid_financials THEN f.profit END) AS total_profit
    FROM {DB}.{SCHEMA}.FACT_BOX_OFFICE f
    JOIN filtered_movies fm ON f.movie_id = fm.movie_id
    GROUP BY YEAR(f.date_key)
    ORDER BY year
""").to_pandas()

if not trend_df.empty:
    fig = px.line(
        trend_df, x="YEAR", y=["TOTAL_REVENUE", "TOTAL_PROFIT"],
        labels={"value": "USD", "YEAR": "Year", "variable": "Metric"},
    )
    st.plotly_chart(fig, use_container_width=True)
else:
    st.info("No data for the current filter selection.")

# ---------- Genre performance ----------
st.subheader("Genre performance")
genre_perf_df = session.sql(f"""
    WITH filtered_movies AS ({movie_ids_cte})
    SELECT
        g.genre_name,
        COUNT(*) AS movie_count,
        SUM(f.revenue) AS total_revenue,
        AVG(CASE WHEN f.has_valid_financials THEN f.roi END) AS avg_roi
    FROM {DB}.{SCHEMA}.FACT_BOX_OFFICE f
    JOIN filtered_movies fm ON f.movie_id = fm.movie_id
    JOIN {DB}.{SCHEMA}.BRIDGE_MOVIE_GENRE bg ON f.movie_id = bg.movie_id
    JOIN {DB}.{SCHEMA}.DIM_GENRE g ON bg.genre_id = g.genre_id
    GROUP BY g.genre_name
    ORDER BY total_revenue DESC
    LIMIT 15
""").to_pandas()

col1, col2 = st.columns(2)
with col1:
    if not genre_perf_df.empty:
        fig = px.bar(genre_perf_df, x="GENRE_NAME", y="TOTAL_REVENUE", title="Total revenue by genre")
        st.plotly_chart(fig, use_container_width=True)
with col2:
    if not genre_perf_df.empty:
        fig = px.bar(genre_perf_df, x="GENRE_NAME", y="AVG_ROI", title="Average ROI by genre")
        st.plotly_chart(fig, use_container_width=True)

# ---------- Budget vs ROI ----------
st.subheader("Budget vs. ROI")
scatter_df = session.sql(f"""
    WITH filtered_movies AS ({movie_ids_cte})
    SELECT f.title, f.budget, f.revenue, f.roi, f.vote_average
    FROM {DB}.{SCHEMA}.FACT_BOX_OFFICE f
    JOIN filtered_movies fm ON f.movie_id = fm.movie_id
    WHERE f.has_valid_financials
    ORDER BY f.revenue DESC
    LIMIT 500
""").to_pandas()

if not scatter_df.empty:
    fig = px.scatter(
        scatter_df, x="BUDGET", y="ROI", size="REVENUE", color="VOTE_AVERAGE",
        hover_name="TITLE", log_x=True,
        labels={"BUDGET": "Budget (USD, log scale)", "ROI": "ROI"},
    )
    st.plotly_chart(fig, use_container_width=True)
else:
    st.info("No movies with valid budget/revenue data for this filter selection.")

# ---------- Top studios ----------
st.subheader("Top studios by total box office")
studio_perf_df = session.sql(f"""
    WITH filtered_movies AS ({movie_ids_cte})
    SELECT s.studio_name, SUM(f.revenue) AS total_revenue, COUNT(*) AS movie_count
    FROM {DB}.{SCHEMA}.FACT_BOX_OFFICE f
    JOIN filtered_movies fm ON f.movie_id = fm.movie_id
    JOIN {DB}.{SCHEMA}.BRIDGE_MOVIE_STUDIO bst ON f.movie_id = bst.movie_id
    JOIN {DB}.{SCHEMA}.DIM_STUDIO s ON bst.studio_id = s.studio_id
    GROUP BY s.studio_name
    ORDER BY total_revenue DESC
    LIMIT 15
""").to_pandas()

if not studio_perf_df.empty:
    fig = px.bar(
        studio_perf_df.sort_values("TOTAL_REVENUE"),
        x="TOTAL_REVENUE", y="STUDIO_NAME", orientation="h",
    )
    st.plotly_chart(fig, use_container_width=True)
else:
    st.info("No data for the current filter selection.")

# ---------- Seasonal release pattern ----------
st.subheader("Do summer or holiday releases outperform?")
season_df = session.sql(f"""
    WITH filtered_movies AS ({movie_ids_cte})
    SELECT
        CASE
            WHEN d.is_summer_release THEN 'Summer'
            WHEN d.is_holiday_release THEN 'Holiday'
            ELSE 'Other'
        END AS season,
        AVG(f.revenue) AS avg_revenue,
        COUNT(*) AS movie_count
    FROM {DB}.{SCHEMA}.FACT_BOX_OFFICE f
    JOIN filtered_movies fm ON f.movie_id = fm.movie_id
    JOIN {DB}.{SCHEMA}.DIM_RELEASE_DATE d ON f.date_key = d.date_key
    GROUP BY season
""").to_pandas()

if not season_df.empty:
    fig = px.bar(season_df, x="SEASON", y="AVG_REVENUE", text="MOVIE_COUNT",
                 labels={"AVG_REVENUE": "Average revenue (USD)"})
    st.plotly_chart(fig, use_container_width=True)
else:
    st.info("No data for the current filter selection.")

st.caption(
    "Data: The Movies Dataset (Kaggle, CC0). Revenue/budget of $0 treated "
    "as unreported and excluded from ROI calculations."
)