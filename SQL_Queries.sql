use new_schema;
WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders,
        MAX(order_date) AS last_order_date
    FROM orders1
    GROUP BY customer_id
)
SELECT customer_id
FROM customer_orders
WHERE total_orders >= 2 
AND last_order_date < DATE_SUB(CURDATE(), INTERVAL 60 DAY);

WITH order_differences AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date
    FROM orders1
)
SELECT 
    customer_id,
    AVG(DATEDIFF(order_date, previous_order_date)) AS avg_days_between_orders
FROM order_differences
WHERE previous_order_date IS NOT NULL  -- Exclude first-time customers
GROUP BY customer_id;

WITH customer_spend AS (
    SELECT 
        customer_id,
        SUM(total_amount) AS total_spend,
        COUNT(order_id) AS total_orders
    FROM orders1
    GROUP BY customer_id
),
customer_rank AS (
    SELECT 
        customer_id,
        total_spend,
        total_orders,
        total_spend / total_orders AS avg_order_value,
        NTILE(10) OVER (ORDER BY total_spend DESC) AS percentile_rank
    FROM customer_spend
)
SELECT 
    customer_id,
    total_spend,
    avg_order_value
FROM customer_rank
WHERE percentile_rank = 1  -- Top 10%
ORDER BY total_spend DESC;

WITH delivery_analysis AS (
    SELECT 
        o.city AS region,  -- Assuming 'city' represents the region
        COUNT(d.order_id) AS total_deliveries,
        SUM(CASE WHEN d.delivery_status = 'On Time' THEN 1 ELSE 0 END) AS on_time_deliveries
    FROM orders1 o
    JOIN delivery_performance d ON o.order_id = d.order_id
    GROUP BY o.city
)
SELECT 
    region,
    total_deliveries,
    on_time_deliveries,
    (on_time_deliveries * 100.0 / total_deliveries) AS on_time_percentage
FROM delivery_analysis
ORDER BY on_time_percentage DESC;

