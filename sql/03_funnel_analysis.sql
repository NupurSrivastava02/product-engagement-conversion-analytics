-- 03_funnel_analysis.sql
-- Conversion funnel for the full analysis period

WITH user_events AS (
  SELECT
    user_pseudo_id,
    event_name
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201101' AND '20201231'
    AND user_pseudo_id IS NOT NULL
),

funnel AS (
  SELECT
    COUNT(DISTINCT user_pseudo_id) AS users,

    COUNT(DISTINCT CASE
      WHEN event_name = 'session_start'
      THEN user_pseudo_id
    END) AS sessions,

    COUNT(DISTINCT CASE
      WHEN event_name = 'view_item'
      THEN user_pseudo_id
    END) AS product_views,

    COUNT(DISTINCT CASE
      WHEN event_name = 'add_to_cart'
      THEN user_pseudo_id
    END) AS add_to_cart,

    COUNT(DISTINCT CASE
      WHEN event_name = 'begin_checkout'
      THEN user_pseudo_id
    END) AS checkouts,

    COUNT(DISTINCT CASE
      WHEN event_name = 'purchase'
      THEN user_pseudo_id
    END) AS purchases

  FROM user_events
)

SELECT
  users,
  sessions,
  product_views,
  add_to_cart,
  checkouts,
  purchases,

  SAFE_DIVIDE(product_views, sessions) * 100
    AS session_to_product_rate,

  SAFE_DIVIDE(add_to_cart, product_views) * 100
    AS product_to_cart_rate,

  SAFE_DIVIDE(checkouts, add_to_cart) * 100
    AS cart_to_checkout_rate,

  SAFE_DIVIDE(purchases, checkouts) * 100
    AS checkout_to_purchase_rate,

  SAFE_DIVIDE(purchases, users) * 100
    AS overall_conversion_rate

FROM funnel;
