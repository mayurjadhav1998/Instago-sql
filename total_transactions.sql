WITH order_status AS (
    SELECT 
        orders.id,
        orders.order_guid,
        orders.dispensing,
        order_payment_types.payment_amount,
        ROW_NUMBER() OVER (PARTITION BY orders.order_guid ORDER BY orders.dispensing DESC) AS rn
    FROM orders
    JOIN order_payment_types ON orders.id = order_payment_types.order_id
),
city_sales AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
        DATE(orders.created_at)::TEXT AS order_date,
        clients.name::VARCHAR AS client_name,
        SUM(CASE 
                WHEN os.rn = 1 AND os.dispensing != 'completed' THEN os.payment_amount 
                ELSE 0 
            END)::NUMERIC AS total_loss,
        COUNT(CASE 
                WHEN os.rn = 1 AND os.dispensing != 'completed' THEN os.payment_amount 
                ELSE NULL 
            END)::NUMERIC AS total_failed_transactions
    FROM orders
    JOIN order_status os ON orders.id = os.id
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE os.rn = 1
	  AND DATE(orders.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
      AND DATE(orders.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
      AND orders.dispensing != 'completed' AND orders.dispensing IS NOT NULL
      AND cities.id = $city_id
      AND clients.id = $client_id

    GROUP BY cities.name, DATE(orders.created_at), clients.name
),
completed_sales AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
        DATE(orders.created_at)::TEXT AS order_date,
        clients.name::VARCHAR AS client_name,
        SUM(os.payment_amount)::NUMERIC AS total_sale,
        COUNT(os.payment_amount)::NUMERIC AS total_completed_transactions
    FROM orders
    JOIN order_status os ON orders.id = os.id
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE os.rn = 1
	  AND DATE(orders.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
      AND DATE(orders.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
      AND orders.dispensing = 'completed'
      AND cities.id = $city_id
      AND clients.id = $client_id

    GROUP BY cities.name, DATE(orders.created_at), clients.name
),
monthly_totals AS (
    SELECT
        'Total' AS city_name,
        UPPER(TO_CHAR(DATE_TRUNC('month', DATE(cs.order_date)), 'YYYY-Mon')) AS order_date,
        cs.client_name,
        SUM(cs.total_loss) AS total_loss,
        SUM(cs.total_failed_transactions) AS total_failed_transactions,
        SUM(cs2.total_sale) AS total_sale,
        SUM(cs2.total_completed_transactions) AS total_completed_transactions,
        SUM(cs.total_failed_transactions)+SUM(cs2.total_completed_transactions) as total_transactions
    FROM city_sales cs
    LEFT JOIN completed_sales cs2
    ON cs.city_name = cs2.city_name 
    AND cs.order_date = cs2.order_date 
    AND cs.client_name = cs2.client_name
    GROUP BY UPPER(TO_CHAR(DATE_TRUNC('month', DATE(cs.order_date)), 'YYYY-Mon')), cs.client_name
),
final_result AS (
    SELECT 
        cs.city_name, 
        cs.order_date, 
        cs.client_name, 
        cs.total_loss, 
        COALESCE(cs2.total_sale, 0) AS total_sale,
        cs.total_failed_transactions,
        COALESCE(cs2.total_completed_transactions, 0) AS total_completed_transactions
    FROM city_sales cs
    LEFT JOIN completed_sales cs2 
    ON cs.city_name = cs2.city_name 
    AND cs.order_date = cs2.order_date 
    AND cs.client_name = cs2.client_name
    UNION ALL
    SELECT 
        mt.city_name, 
        mt.order_date, 
        mt.client_name, 
        mt.total_loss, 
        mt.total_sale,
        mt.total_failed_transactions,
        mt.total_completed_transactions
    FROM monthly_totals mt
),
sum_total AS (
    SELECT *,
           SUM(fr.total_failed_transactions)+SUM(fr.total_completed_transactions) AS total_transactions
    FROM final_result fr
    GROUP BY fr.city_name, fr.order_date, fr.client_name, fr.total_loss, 
             fr.total_sale, fr.total_completed_transactions, fr.total_failed_transactions
    ORDER BY order_date DESC, city_name
)
SELECT * FROM sum_total
ORDER BY order_date DESC, city_name;
