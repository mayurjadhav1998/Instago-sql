WITH completed_orders AS (
    SELECT DISTINCT order_guid
    FROM orders
    JOIN machines ON orders.registration_id = machines.registration_id
    WHERE dispensing = 'completed'
    AND machines.client_id = 243
    AND DATE(orders.created_at) >= '2024-06-01'
    AND DATE(orders.created_at) <= '2024-06-30'
),
order_status AS (
    SELECT 
        orders.order_guid,
        MAX(orders.dispensing) AS max_dispensing_status,
        SUM(CASE 
                WHEN orders.dispensing IS NOT NULL THEN op.product_quantity * p.mrp 
                ELSE 0 
            END) AS purchase_amount,
        SUM(order_payment_types.payment_amount) AS total_payment
    FROM orders
    LEFT JOIN order_payment_types ON orders.id = order_payment_types.order_id
    LEFT JOIN orders_products op ON orders.id = op.order_id
    LEFT JOIN products p ON op.product_id = p.id
    JOIN machines ON orders.registration_id = machines.registration_id
    WHERE machines.client_id = 243
    AND DATE(orders.created_at) >= '2024-06-01'
    AND DATE(orders.created_at) <= '2024-06-30'
    GROUP BY orders.order_guid
),
sales_data AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
        DATE(orders.created_at)::TEXT AS order_date,
        clients.name::VARCHAR AS client_name,
        SUM(CASE 
            WHEN os.max_dispensing_status = 'started' AND os.order_guid NOT IN (SELECT order_guid FROM completed_orders) THEN os.total_payment ELSE 0 END
        ) AS total_possible_loss,
        SUM(CASE 
            WHEN os.max_dispensing_status != 'completed' AND os.order_guid NOT IN (SELECT order_guid FROM completed_orders) THEN os.purchase_amount ELSE 0 END
        ) AS total_purchase_loss,
        COUNT(CASE 
            WHEN os.max_dispensing_status != 'completed' AND os.order_guid NOT IN (SELECT order_guid FROM completed_orders) THEN 1 ELSE NULL END
        ) AS total_failed_transactions,
        SUM(CASE 
            WHEN os.max_dispensing_status = 'completed' THEN os.total_payment ELSE 0 END
        ) AS total_sale,
        COUNT(CASE 
            WHEN os.max_dispensing_status = 'completed' THEN 1 ELSE NULL END
        ) AS total_completed_transactions
    FROM orders
    JOIN order_status os ON orders.order_guid = os.order_guid
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE cities.id = 11 -- $city_id
      AND clients.id = 243 -- $client_id
    GROUP BY cities.name, DATE(orders.created_at), clients.name
),
monthly_totals AS (
    SELECT
        'Total' AS city_name,
        UPPER(TO_CHAR(DATE_TRUNC('month', DATE(sd.order_date)), 'YYYY-Mon')) AS order_date,
        sd.client_name,
        SUM(sd.total_possible_loss) AS total_possible_loss,
        SUM(sd.total_purchase_loss) AS total_purchase_loss,
        SUM(sd.total_failed_transactions) AS total_failed_transactions,
        SUM(sd.total_sale) AS total_sale,
        SUM(sd.total_completed_transactions) AS total_completed_transactions,
        SUM(sd.total_failed_transactions) + SUM(sd.total_completed_transactions) AS total_transactions
    FROM sales_data sd
    GROUP BY UPPER(TO_CHAR(DATE_TRUNC('month', DATE(sd.order_date)), 'YYYY-Mon')), sd.client_name
),
final_result AS (
    SELECT 
        sd.city_name, 
        sd.order_date, 
        sd.client_name, 
        sd.total_possible_loss,
        sd.total_purchase_loss,
        sd.total_sale,
        sd.total_failed_transactions,
        sd.total_completed_transactions
    FROM sales_data sd
    UNION ALL
    SELECT 
        mt.city_name, 
        mt.order_date, 
        mt.client_name, 
        mt.total_possible_loss,
        mt.total_purchase_loss,
        mt.total_sale,
        mt.total_failed_transactions,
        mt.total_completed_transactions
    FROM monthly_totals mt
)
SELECT 
    fr.city_name, 
    fr.order_date, 
    fr.client_name, 
    fr.total_possible_loss, 
    fr.total_purchase_loss,
    fr.total_sale,
    fr.total_failed_transactions,
    fr.total_completed_transactions,
    (fr.total_failed_transactions + fr.total_completed_transactions) AS total_transactions
FROM final_result fr
ORDER BY fr.order_date DESC, fr.city_name;
