WITH distinct_order AS (
    SELECT DISTINCT order_guid, *
    FROM orders
    WHERE orders.dispensing = 'completed'
),

completed_orders AS (
    SELECT DISTINCT order_guid AS order_guid1, orders.*
    FROM orders
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE 
        DATE(orders.created_at) >= '2024-06-01'
        AND DATE(orders.created_at) <= '2024-06-30'
        AND cities.id = $city_id
        AND clients.id = $client_id 
        AND dispensing = 'completed'
    GROUP BY cities.name, DATE(orders.created_at), clients.name, order_guid1, orders.id
),

started_orders AS (
    SELECT DISTINCT order_guid AS order_guid1, orders.*
    FROM orders
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE 
        DATE(orders.created_at) >= '2024-06-01'
        AND DATE(orders.created_at) <= '2024-06-30'
        AND cities.id = $city_id
        AND clients.id = $client_id 
        AND dispensing = 'started'
        AND order_guid NOT IN (
            SELECT order_guid
            FROM completed_orders
        )
    GROUP BY cities.name, DATE(orders.created_at), clients.name, order_guid1, orders.id
),

order_details_started AS (
    SELECT 
        order_guid1,
        SUM(product_quantity * mrp) AS purchase_amount,
        order_payment_types.payment_amount AS total_payment
    FROM started_orders
    JOIN order_payment_types ON started_orders.id = order_payment_types.order_id
    JOIN orders_products op ON started_orders.id = op.order_id
    JOIN products p ON op.product_id = p.id
    WHERE dispensing IS NOT NULL
        AND DATE(started_orders.created_at) >= '2024-06-01'
        AND DATE(started_orders.created_at) <= '2024-06-30'
    GROUP BY order_guid1, payment_amount
),

order_details_completed AS (
    SELECT 
        order_guid1,
        SUM(product_quantity * mrp) AS purchase_amount,
        order_payment_types.payment_amount AS total_payment
    FROM completed_orders
    JOIN order_payment_types ON completed_orders.id = order_payment_types.order_id
    JOIN orders_products op ON completed_orders.id = op.order_id
    JOIN products p ON op.product_id = p.id 
    WHERE dispensing IS NOT NULL
        AND DATE(completed_orders.created_at) >= '2024-06-01'
        AND DATE(completed_orders.created_at) <= '2024-06-30'
    GROUP BY order_guid1, payment_amount
),

started_sales_data AS (
    SELECT 
        COUNT(order_details_started.order_guid1) AS total_started_transactions,
        SUM(order_details_started.total_payment) AS total_possible_loss
    FROM order_details_started
),

completed_sales_data AS (
    SELECT 
        COUNT(order_details_completed.order_guid1) AS total_completed_transactions, 
        SUM(order_details_completed.total_payment) AS total_sale
    FROM order_details_completed
),

sales_data AS (
    SELECT 
        (completed_sales_data.total_completed_transactions + started_sales_data.total_started_transactions) AS total_transactions,
        completed_sales_data.total_completed_transactions, 
        started_sales_data.total_started_transactions, 
        (completed_sales_data.total_sale + started_sales_data.total_possible_loss) AS total_order_value,
        completed_sales_data.total_sale,
        started_sales_data.total_possible_loss,
        (started_sales_data.total_possible_loss / (completed_sales_data.total_sale + started_sales_data.total_possible_loss) * 100) AS total_loss_percentage
    FROM completed_sales_data
    CROSS JOIN started_sales_data
)	

select * from sales_data
-- Check data in started_sales_data
--SELECT * FROM started_sales_data;

-- Check data in completed_sales_data
--SELECT * FROM completed_sales_data;
--
---- Check data in order_details_started
--SELECT * FROM order_details_started;
--
---- Check data in order_details_completed
--SELECT * FROM order_details_completed;
------------------------------------------------------------------------------------------------------------
--
--WITH consecutive_started AS (
--    SELECT
--        o.*,
--        opt.payment_amount,
--        ROW_NUMBER() OVER (ORDER BY o.created_at) AS rn,
--        LAG(dispensing) OVER (ORDER BY o.created_at) AS prev_dispensing
--    FROM orders o
--    JOIN order_payment_types opt ON o.id = opt.order_id
--    WHERE registration_id = '15261c8f-4339-4a6e-917d-3442c44bb5c5'
--      AND date(o.created_at) >= '2024-06-07'
--      AND date(o.created_at) <= '2024-06-07'
--),
--consecutive_counts AS (
--    SELECT
--        *,
--        CASE
--            WHEN dispensing = 'started' AND prev_dispensing = 'started' THEN 1
--            ELSE 0
--        END AS is_started_consecutive
--    FROM consecutive_started
--),
--counts_with_minimum AS (
--    SELECT
--        *,
--        CASE
--            WHEN is_started_consecutive = 1 AND
--                 (LAG(is_started_consecutive) OVER (ORDER BY rn) = 1 OR LAG(is_started_consecutive, 2) OVER (ORDER BY rn) = 1)
--            THEN 1
--            ELSE 0
--        END AS should_count
--    FROM consecutive_counts
--),
--counts_with_reset AS (
--    SELECT
--        *,
--        SUM(should_count) OVER (ORDER BY rn ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS started_count
--    FROM counts_with_minimum
--),
--final_counts AS (
--    SELECT
--        *,
--        CASE
--            WHEN dispensing = 'completed' THEN 0
--            ELSE started_count
--        END AS started_count
--    FROM counts_with_reset
--)
--SELECT *
--FROM final_counts
--ORDER BY created_at;
