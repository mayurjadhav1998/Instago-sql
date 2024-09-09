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
    WHERE dispensing IS not NULL 
      AND dispensing = 'completed' 
     -- AND dispensing != 'started'
      --and DATE(orders.created_at) >='2024-08-1'     AND DATE(orders.created_at) <='2024-09-4'

      AND DATE(orders.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
      AND DATE(orders.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
      and machines.client_id =$client_id
     -- AND machines.id = $machine_id
    GROUP BY cities.name, DATE(orders.created_at), clients.name,machines.machine_number
)

SELECT * FROM city_sales

UNION ALL

SELECT
    'Total' AS city_name,
    UPPER(TO_CHAR(DATE_TRUNC('month', DATE(city_sales.order_date)), 'YYYY-Mon')) AS order_date,
    client_name AS client_name,
    machine_name as machine_name,
    SUM(total_sales) AS total_sales
FROM city_sales
GROUP BY client_name,
         UPPER(TO_CHAR(DATE_TRUNC('month', DATE(city_sales.order_date)), 'YYYY-Mon')),city_sales.machine_name
ORDER BY city_name DESC;
