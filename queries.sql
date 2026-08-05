
-- ============================================================
-- UrbanCart Big Data Analytics
-- Phase 1: SQL Data Extraction
-- Database: SQLite (ecommerce.db)
-- ============================================================


-- Query 1: Calculate net revenue, order count, and average order
-- value by product category after accounting for discounts.
SELECT
    p.category,
    ROUND(
        SUM(
            oi.quantity
            * oi.unit_price
            * (1 - COALESCE(oi.discount, 0))
        ),
        2
    ) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(
        SUM(
            oi.quantity
            * oi.unit_price
            * (1 - COALESCE(oi.discount, 0))
        ) / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    ) AS average_order_value
FROM order_items AS oi
JOIN products AS p
    ON oi.product_id = p.product_id
JOIN orders AS o
    ON oi.order_id = o.order_id
WHERE LOWER(o.status) = 'completed'
GROUP BY p.category
ORDER BY total_revenue DESC;


-- ============================================================


-- Query 2: Identify the top 20 customers by lifetime spending,
-- including their city and signup date.
SELECT
    c.customer_id,
    c.name,
    c.city,
    c.signup_date,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(
        SUM(
            oi.quantity
            * oi.unit_price
            * (1 - COALESCE(oi.discount, 0))
        ),
        2
    ) AS lifetime_spending
FROM customers AS c
JOIN orders AS o
    ON c.customer_id = o.customer_id
JOIN order_items AS oi
    ON o.order_id = oi.order_id
WHERE LOWER(o.status) = 'completed'
GROUP BY
    c.customer_id,
    c.name,
    c.city,
    c.signup_date
ORDER BY lifetime_spending DESC
LIMIT 20;


-- ============================================================


-- Query 3: Show the month-over-month revenue trend for the most
-- recent 24 months, including previous revenue and percentage change.
WITH monthly_revenue AS (
    SELECT
        STRFTIME('%Y-%m', o.order_date) AS revenue_month,
        ROUND(
            SUM(
                oi.quantity
                * oi.unit_price
                * (1 - COALESCE(oi.discount, 0))
            ),
            2
        ) AS revenue
    FROM orders AS o
    JOIN order_items AS oi
        ON o.order_id = oi.order_id
    WHERE LOWER(o.status) = 'completed'
    GROUP BY STRFTIME('%Y-%m', o.order_date)
),
recent_24_months AS (
    SELECT
        revenue_month,
        revenue
    FROM monthly_revenue
    ORDER BY revenue_month DESC
    LIMIT 24
),
monthly_comparison AS (
    SELECT
        revenue_month,
        revenue,
        LAG(revenue) OVER (
            ORDER BY revenue_month
        ) AS previous_month_revenue
    FROM recent_24_months
)
SELECT
    revenue_month,
    revenue,
    previous_month_revenue,
    ROUND(
        revenue - previous_month_revenue,
        2
    ) AS revenue_change,
    ROUND(
        100.0 * (revenue - previous_month_revenue)
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS percentage_change
FROM monthly_comparison
ORDER BY revenue_month;


-- ============================================================


-- Query 4: Calculate the return rate for each category. Negative
-- quantities represent returned units.
WITH category_item_summary AS (
    SELECT
        p.category,
        COUNT(*) AS total_item_rows,
        SUM(
            CASE
                WHEN oi.quantity < 0 THEN 1
                ELSE 0
            END
        ) AS returned_item_rows,
        SUM(ABS(oi.quantity)) AS total_units,
        SUM(
            CASE
                WHEN oi.quantity < 0 THEN ABS(oi.quantity)
                ELSE 0
            END
        ) AS returned_units
    FROM order_items AS oi
    JOIN products AS p
        ON oi.product_id = p.product_id
    GROUP BY p.category
)
SELECT
    category,
    total_item_rows,
    returned_item_rows,
    returned_units,
    total_units,
    ROUND(
        100.0 * returned_item_rows
        / NULLIF(total_item_rows, 0),
        2
    ) AS return_row_rate_percent,
    ROUND(
        100.0 * returned_units
        / NULLIF(total_units, 0),
        2
    ) AS return_unit_rate_percent
FROM category_item_summary
ORDER BY return_unit_rate_percent DESC;


-- ============================================================


-- Query 5: Find customers who placed at least one completed order
-- in every one of the latest three calendar quarters in the data.
WITH latest_date AS (
    SELECT
        MAX(DATE(order_date)) AS maximum_order_date
    FROM orders
),
latest_quarter AS (
    SELECT
        DATE(
            STRFTIME('%Y', maximum_order_date)
            || '-'
            || PRINTF(
                '%02d',
                (
                    (
                        CAST(STRFTIME('%m', maximum_order_date) AS INTEGER)
                        - 1
                    ) / 3
                ) * 3 + 1
            )
            || '-01'
        ) AS current_quarter_start
    FROM latest_date
),
required_quarters AS (
    SELECT current_quarter_start AS quarter_start
    FROM latest_quarter

    UNION ALL

    SELECT DATE(current_quarter_start, '-3 months')
    FROM latest_quarter

    UNION ALL

    SELECT DATE(current_quarter_start, '-6 months')
    FROM latest_quarter
),
customer_quarters AS (
    SELECT DISTINCT
        o.customer_id,
        DATE(
            STRFTIME('%Y', o.order_date)
            || '-'
            || PRINTF(
                '%02d',
                (
                    (
                        CAST(STRFTIME('%m', o.order_date) AS INTEGER)
                        - 1
                    ) / 3
                ) * 3 + 1
            )
            || '-01'
        ) AS quarter_start
    FROM orders AS o
    WHERE LOWER(o.status) = 'completed'
)
SELECT
    c.customer_id,
    c.name,
    c.city,
    c.signup_date,
    COUNT(DISTINCT cq.quarter_start) AS active_required_quarters
FROM customers AS c
JOIN customer_quarters AS cq
    ON c.customer_id = cq.customer_id
JOIN required_quarters AS rq
    ON cq.quarter_start = rq.quarter_start
GROUP BY
    c.customer_id,
    c.name,
    c.city,
    c.signup_date
HAVING COUNT(DISTINCT cq.quarter_start) = 3
ORDER BY c.name;


-- ============================================================


-- Query 6: Return the 10 products with the highest valid average
-- review rating among products with at least 15 valid reviews.
SELECT
    p.product_id,
    p.name,
    p.category,
    COUNT(r.review_id) AS total_reviews,
    ROUND(AVG(r.rating), 2) AS average_rating
FROM products AS p
JOIN reviews AS r
    ON p.product_id = r.product_id
WHERE r.rating BETWEEN 1 AND 5
GROUP BY
    p.product_id,
    p.name,
    p.category
HAVING COUNT(r.review_id) >= 15
ORDER BY
    average_rating DESC,
    total_reviews DESC,
    p.name
LIMIT 10;


-- ============================================================


-- Query 7: Calculate average session duration and pages viewed by
-- device for customers who made at least one completed purchase.
SELECT
    ws.device,
    COUNT(*) AS total_sessions,
    COUNT(DISTINCT ws.customer_id) AS purchasing_customers,
    ROUND(AVG(ws.duration_minutes), 2) AS average_duration_minutes,
    ROUND(AVG(ws.pages_viewed), 2) AS average_pages_viewed
FROM web_sessions AS ws
WHERE EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.customer_id = ws.customer_id
      AND LOWER(o.status) = 'completed'
)
GROUP BY ws.device
ORDER BY average_duration_minutes DESC;


-- ============================================================


-- Query 8: Rank products by net revenue within each product category.
WITH product_revenue AS (
    SELECT
        p.category,
        p.product_id,
        p.name,
        ROUND(
            SUM(
                oi.quantity
                * oi.unit_price
                * (1 - COALESCE(oi.discount, 0))
            ),
            2
        ) AS net_revenue
    FROM products AS p
    JOIN order_items AS oi
        ON p.product_id = oi.product_id
    JOIN orders AS o
        ON oi.order_id = o.order_id
    WHERE LOWER(o.status) = 'completed'
    GROUP BY
        p.category,
        p.product_id,
        p.name
)
SELECT
    category,
    product_id,
    name,
    net_revenue,
    DENSE_RANK() OVER (
        PARTITION BY category
        ORDER BY net_revenue DESC
    ) AS revenue_rank
FROM product_revenue
ORDER BY
    category,
    revenue_rank,
    name;


-- ============================================================


-- Query 9: Show the payment-method mix by customer country as both
-- order count and percentage share of orders within each country.
WITH country_payment_orders AS (
    SELECT
        c.country,
        o.payment_method,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM customers AS c
    JOIN orders AS o
        ON c.customer_id = o.customer_id
    WHERE LOWER(o.status) = 'completed'
    GROUP BY
        c.country,
        o.payment_method
)
SELECT
    country,
    payment_method,
    order_count,
    ROUND(
        100.0 * order_count
        / SUM(order_count) OVER (
            PARTITION BY country
        ),
        2
    ) AS payment_method_share_percent
FROM country_payment_orders
ORDER BY
    country,
    payment_method_share_percent DESC;


-- ============================================================


-- Query 10: Leadership should identify high-value customers who may
-- be at risk of churn so retention campaigns can be prioritized.
WITH customer_activity AS (
    SELECT
        c.customer_id,
        c.name,
        c.city,
        c.country,
        MAX(DATE(o.order_date)) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS completed_orders,
        ROUND(
            SUM(
                oi.quantity
                * oi.unit_price
                * (1 - COALESCE(oi.discount, 0))
            ),
            2
        ) AS lifetime_revenue
    FROM customers AS c
    JOIN orders AS o
        ON c.customer_id = o.customer_id
    JOIN order_items AS oi
        ON o.order_id = oi.order_id
    WHERE LOWER(o.status) = 'completed'
    GROUP BY
        c.customer_id,
        c.name,
        c.city,
        c.country
),
dataset_reference_date AS (
    SELECT MAX(DATE(order_date)) AS latest_order_date
    FROM orders
)
SELECT
    ca.customer_id,
    ca.name,
    ca.city,
    ca.country,
    ca.last_order_date,
    CAST(
        JULIANDAY(drd.latest_order_date)
        - JULIANDAY(ca.last_order_date)
        AS INTEGER
    ) AS days_since_last_order,
    ca.completed_orders,
    ca.lifetime_revenue,
    CASE
        WHEN ca.lifetime_revenue >= 5000
             AND (
                 JULIANDAY(drd.latest_order_date)
                 - JULIANDAY(ca.last_order_date)
             ) >= 90
        THEN 'High-value churn risk'

        WHEN ca.lifetime_revenue >= 5000
        THEN 'High-value active'

        WHEN (
             JULIANDAY(drd.latest_order_date)
             - JULIANDAY(ca.last_order_date)
             ) >= 90
        THEN 'Inactive'

        ELSE 'Active'
    END AS customer_status
FROM customer_activity AS ca
CROSS JOIN dataset_reference_date AS drd
ORDER BY
    CASE customer_status
        WHEN 'High-value churn risk' THEN 1
        WHEN 'High-value active' THEN 2
        WHEN 'Inactive' THEN 3
        ELSE 4
    END,
    ca.lifetime_revenue DESC;
