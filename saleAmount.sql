WITH city_sales AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
        TO_CHAR(DATE(orders.created_at), 'YYYY-MM-DD') AS order_date,
        clients.name::VARCHAR AS client_name,
        machines.machine_number as machine_name,
        SUM(order_payment_types.payment_amount)::NUMERIC AS total_sales
    FROM orders
    JOIN order_payment_types ON orders.id = order_payment_types.order_id
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE dispensing IS NOT NULL 
      AND dispensing = 'completed' 
      AND DATE(orders.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
      AND DATE(orders.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
      AND machines.id = $machine_id
    GROUP BY cities.name, DATE(orders.created_at), clients.name, machines.machine_number
),
tbls AS (
    SELECT * FROM city_sales

    UNION ALL

    SELECT
        'Total' AS city_name,
        UPPER(TO_CHAR(DATE_TRUNC('month', DATE(city_sales.order_date)), 'YYYY-Mon')) AS order_date,
        client_name AS client_name,
        machine_name AS machine_name,
        SUM(total_sales) AS total_sale
    FROM city_sales
    GROUP BY client_name,
             UPPER(TO_CHAR(DATE_TRUNC('month', DATE(city_sales.order_date)), 'YYYY-Mon')), city_sales.machine_name
    ORDER BY city_name DESC
),
completed_orders AS (
    SELECT DISTINCT order_guid
    FROM orders
    JOIN machines ON orders.registration_id = machines.registration_id
    WHERE dispensing = 'completed'
      AND machines.client_id = $client_id
      AND DATE(orders.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
      AND DATE(orders.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
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
        cs.city_name,
        cs.order_date,
        cs.client_name,
        cs.machine_name,
        cs.total_sales AS total_sale, -- Use total_sales from city_sales
        SUM(CASE 
            WHEN os.max_dispensing_status != 'completed' AND os.order_guid NOT IN (SELECT order_guid FROM completed_orders) THEN os.total_payment ELSE 0 END
        ) AS total_loss,
        COUNT(CASE 
            WHEN os.max_dispensing_status != 'completed' AND os.order_guid NOT IN (SELECT order_guid FROM completed_orders) THEN 1 ELSE NULL END
        ) AS total_failed_transactions,
        COUNT(CASE 
            WHEN os.max_dispensing_status = 'completed' THEN 1 ELSE NULL END
        ) AS total_completed_transactions
    FROM orders
    JOIN order_status os ON orders.order_guid = os.order_guid
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    JOIN city_sales cs ON cs.city_name = cities.name 
                      AND cs.order_date = TO_CHAR(DATE(orders.created_at), 'YYYY-MM-DD') 
                      AND cs.client_name = clients.name
                      AND cs.machine_name = machines.machine_number
    WHERE clients.id = $client_id
    GROUP BY cs.city_name, cs.order_date, cs.client_name, cs.machine_name, cs.total_sales
),
monthly_totals AS (
    SELECT
        'Total' AS city_name,
        UPPER(TO_CHAR(DATE_TRUNC('month', DATE(sd.order_date)), 'YYYY-Mon')) AS order_date,
        sd.client_name,
        sd.machine_name,
        SUM(sd.total_loss) AS total_loss,
        SUM(sd.total_failed_transactions) AS total_failed_transactions,
        SUM(sd.total_sale) AS total_sale,
        SUM(sd.total_completed_transactions) AS total_completed_transactions,
        SUM(sd.total_failed_transactions) + SUM(sd.total_completed_transactions) AS total_transactions
    FROM sales_data sd
    GROUP BY UPPER(TO_CHAR(DATE_TRUNC('month', DATE(sd.order_date)), 'YYYY-Mon')), sd.client_name, sd.machine_name
),
final_result AS (
    SELECT 
        sd.city_name, 
        sd.order_date, 
        sd.client_name,
        sd.machine_name,
        sd.total_loss, 
        sd.total_sale,
        sd.total_failed_transactions,
        sd.total_completed_transactions
    FROM sales_data sd
    UNION ALL
    SELECT 
        mt.city_name, 
        mt.order_date, 
        mt.client_name, 
        mt.machine_name,
        mt.total_loss, 
        mt.total_sale,
        mt.total_failed_transactions,
        mt.total_completed_transactions
    FROM monthly_totals mt
),
merged_result AS (
    SELECT 
        city_name,
        order_date,
        client_name,
        machine_name,
        total_sales AS total_sale,
        null::NUMERIC AS total_loss,
        null::NUMERIC AS total_failed_transactions,
        null::NUMERIC AS total_completed_transactions
    FROM tbls

    UNION ALL

    SELECT 
        city_name, 
        order_date, 
        client_name,
        machine_name,
        total_sale,
        total_loss,
        total_failed_transactions,
        total_completed_transactions
    FROM final_result
)
SELECT 
    city_name, 
    order_date, 
    client_name,
    machine_name,
    total_loss, 
    total_sale,
    total_failed_transactions,
    total_completed_transactions,
    (total_failed_transactions + total_completed_transactions) AS total_transactions
FROM final_result
ORDER BY order_date DESC, city_name;
