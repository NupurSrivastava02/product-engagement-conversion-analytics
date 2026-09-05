CREATE OR REPLACE TABLE
  `product-engagement-analytics.product_analytics.user_early_engagement` AS

WITH user_events AS (
  SELECT
    user_pseudo_id,
    event_timestamp,
    event_name
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20201231'
    AND user_pseudo_id IS NOT NULL
),

first_event AS (
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS first_event_time
  FROM user_events
  GROUP BY user_pseudo_id
),

first_purchase AS (
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS first_purchase_time
  FROM user_events
  WHERE event_name = 'purchase'
  GROUP BY user_pseudo_id
),

early_events AS (
  SELECT
    e.user_pseudo_id,
    e.event_timestamp,
    e.event_name,
    p.first_purchase_time

  FROM user_events e

  INNER JOIN first_event f
    ON e.user_pseudo_id = f.user_pseudo_id

  LEFT JOIN first_purchase p
    ON e.user_pseudo_id = p.user_pseudo_id

  WHERE
    e.event_timestamp >= f.first_event_time
    AND e.event_timestamp < f.first_event_time + 24 * 60 * 60 * 1000000

    -- Prevent events at/after the first purchase from becoming predictors
    AND (
      p.first_purchase_time IS NULL
      OR e.event_timestamp < p.first_purchase_time
    )
),

user_early_features AS (
  SELECT
    e.user_pseudo_id,

    CASE
      WHEN p.first_purchase_time IS NOT NULL THEN 1
      ELSE 0
    END AS purchased,

    COUNT(*) AS early_total_events,

    COUNTIF(e.event_name = 'session_start') AS early_sessions,

    COUNTIF(e.event_name = 'view_item') AS early_product_views,

    COUNTIF(e.event_name = 'add_to_cart') AS early_add_to_cart,

    COUNTIF(e.event_name = 'begin_checkout') AS early_checkouts,

    COUNTIF(e.event_name = 'search') AS early_searches,

    COUNTIF(e.event_name = 'select_item') AS early_item_selections

  FROM early_events e

  LEFT JOIN first_purchase p
    ON e.user_pseudo_id = p.user_pseudo_id

  GROUP BY
    e.user_pseudo_id,
    purchased
)

SELECT *
FROM user_early_features;
