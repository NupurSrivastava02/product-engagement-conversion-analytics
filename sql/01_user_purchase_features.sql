CREATE OR REPLACE TABLE
  `product-engagement-analytics.product_analytics.user_purchase_features` AS

WITH user_events AS (
  SELECT
    user_pseudo_id,
    event_timestamp,
    event_name,

    -- Extract device category
    device.category AS device_category

  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`

  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20201231'
    AND user_pseudo_id IS NOT NULL
),

first_purchase AS (
  SELECT
    user_pseudo_id,
    MIN(event_timestamp) AS first_purchase_time

  FROM user_events

  WHERE event_name = 'purchase'

  GROUP BY user_pseudo_id
),

user_features AS (
  SELECT
    e.user_pseudo_id,

    -- Purchase outcome
    CASE
      WHEN p.first_purchase_time IS NOT NULL THEN 1
      ELSE 0
    END AS purchased,

    -- Engagement
    COUNT(*) AS total_events,

    COUNT(DISTINCT DATE(TIMESTAMP_MICROS(e.event_timestamp))) AS active_days,

    COUNTIF(e.event_name = 'session_start') AS sessions,

    -- Funnel behaviors
    COUNTIF(e.event_name = 'view_item') AS product_views,

    COUNTIF(e.event_name = 'add_to_cart') AS add_to_cart,

    COUNTIF(e.event_name = 'begin_checkout') AS checkouts,

    COUNTIF(e.event_name = 'search') AS searches,

    COUNTIF(e.event_name = 'select_item') AS item_selections

  FROM user_events e

  LEFT JOIN first_purchase p
    ON e.user_pseudo_id = p.user_pseudo_id

  GROUP BY
    e.user_pseudo_id,
    purchased
)

SELECT *
FROM user_features;
