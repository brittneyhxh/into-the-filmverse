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