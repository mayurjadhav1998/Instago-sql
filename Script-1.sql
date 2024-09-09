WITH completed_orders AS (
    SELECT DISTINCT order_guid,
           SUM(opt.payment_amount) AS total_sale -- Carry total_sale
    FROM orders
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN order_payment_types opt ON orders.id = opt.order_id
    WHERE dispensing = 'completed'
    AND machines.id = $machine_id
    AND DATE(orders.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
    AND DATE(orders.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
    GROUP BY orders.order_guid
),
order_status AS (
    SELECT 
        orders.order_guid,
        MAX(orders.dispensing) AS max_dispensing_status,
        SUM(order_payment_types.payment_amount) AS total_payment
    FROM orders
    JOIN order_payment_types ON orders.id = order_payment_types.order_id
    WHERE orders.dispensing IS NOT NULL
    AND DATE(orders.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
    AND DATE(orders.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
    GROUP BY orders.order_guid
),
sales_data AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
        DATE(orders.created_at)::TEXT AS order_date,
        clients.name::VARCHAR AS client_name,
        COALESCE(co.total_sale, 0) AS total_sale, -- Carry total_sale from completed_orders
        SUM(CASE 
            -- Only count as total_loss if the order is not completed
            WHEN os.max_dispensing_status != 'completed' 
                AND os.order_guid NOT IN (SELECT order_guid FROM completed_orders) THEN os.total_payment 
            ELSE 0 
        END) AS total_loss,
        COUNT(CASE 
            -- Only count failed transactions if the order is not completed
            WHEN os.max_dispensing_status != 'completed' 
                AND os.order_guid NOT IN (SELECT order_guid FROM completed_orders) THEN 1 
            ELSE NULL 
        END) AS total_failed_transactions,
        COUNT(CASE 
            -- Count completed transactions from the order status
            WHEN os.max_dispensing_status = 'completed' THEN 1 
            ELSE NULL 
        END) AS total_completed_transactions
    FROM orders
    JOIN order_status os ON orders.order_guid = os.order_guid
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    LEFT JOIN completed_orders co ON os.order_guid = co.order_guid -- Join to get total_sale from completed_orders
    WHERE machines.id = $machine_id
    GROUP BY cities.name, DATE(orders.created_at), clients.name, co.total_sale
),
monthly_totals AS (
    SELECT
        'Total' AS city_name,
        UPPER(TO_CHAR(DATE_TRUNC('month', DATE(sd.order_date)), 'YYYY-Mon')) AS order_date,
        sd.client_name,
        SUM(sd.total_loss) AS total_loss,
        SUM(sd.total_failed_transactions) AS total_failed_transactions,
        SUM(sd.total_sale) AS total_sale, -- Include total_sale here
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
        sd.total_loss, 
        sd.total_sale, -- Include total_sale in the final result
        sd.total_failed_transactions,
        sd.total_completed_transactions
    FROM sales_data sd
    UNION ALL
    SELECT 
        mt.city_name, 
        mt.order_date, 
        mt.client_name, 
        mt.total_loss, 
        mt.total_sale, -- Include total_sale in the monthly totals
        mt.total_failed_transactions,
        mt.total_completed_transactions
    FROM monthly_totals mt
)
SELECT 
    fr.city_name, 
    fr.order_date, 
    fr.client_name, 
    fr.total_loss, 
    fr.total_sale, -- Output total_sale in the final result
    fr.total_failed_transactions,
    fr.total_completed_transactions,
    (fr.total_failed_transactions + fr.total_completed_transactions) AS total_transactions
FROM final_result fr 
ORDER BY fr.order_date DESC, fr.city_name;
