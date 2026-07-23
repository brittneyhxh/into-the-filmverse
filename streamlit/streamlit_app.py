import streamlit as st
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Film Analytics", layout="wide")
st.title("Film Analytics")
st.caption("Box office & industry trends, powered by Snowflake + Streamlit")

session = get_active_session()

st.info(
    "PLACEHOLDER"
)

# check Snowflake connection
st.write("Connected as role:", session.get_current_role())
st.write("Current warehouse:", session.get_current_warehouse())
st.write("Current database:", session.get_current_database())
