
/*WITH city_sales AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
        DATE(orders.created_at) AS order_date,
        clients.name::VARCHAR AS client_name,
        SUM(order_payment_types.payment_amount)::NUMERIC AS total_sales
    FROM orders
    JOIN order_payment_types ON orders.id = order_payment_types.order_id
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE orders.dispensing = 'completed'
      AND cities.id = 10
      AND DATE(orders.created_at) BETWEEN '2023-07-01' AND '2023-07-30'
      AND clients.id = 112
    GROUP BY cities.name, DATE(orders.created_at), clients.name
)
SELECT * FROM city_sales;
*/
/*
 * 
 */

WITH city_sales AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
        DATE(orders.created_at) AS order_date,
        clients.name::VARCHAR AS client_name,
        SUM(order_payment_types.payment_amount)::NUMERIC AS total_sales
    FROM orders
    JOIN order_payment_types ON orders.id = order_payment_types.order_id
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE orders.dispensing = 'completed' 
      AND cities.id = $city_id
AND DATE(orders.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
AND DATE(orders.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
      AND clients.id = $client_id
    GROUP BY cities.name, DATE(orders.created_at), clients.name
)
SELECT * FROM city_sales
UNION ALL

SELECT 
    'total' AS city_name,
    $Start_date AS order_date,
    client_name,
    SUM(total_sales) AS total_sales
FROM city_sales
GROUP BY order_date, client_name
ORDER BY city_name, order_date;




























/*
WITH city_sales AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
        DATE(orders.created_at) AS order_date,
        clients.name::VARCHAR AS client_name,
        SUM(order_payment_types.payment_amount)::NUMERIC AS total_sales
    FROM orders
    JOIN order_payment_types ON orders.id = order_payment_types.order_id
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE orders.dispensing = 'completed' 
      AND cities.id = $city_id
      AND DATE(orders.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
      AND DATE(orders.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
      AND clients.id = $client_id
    GROUP BY cities.name, DATE(orders.created_at), clients.name
)
SELECT city_name, order_date, client_name, total_sales
FROM city_sales

UNION ALL

SELECT 
    'total' AS city_name,
    TO_CHAR(order_date, 'Mon-YYYY') AS order_date,
    client_name,
    SUM(total_sales) AS total_sales
FROM city_sales
GROUP BY TO_CHAR(order_date, 'Mon-YYYY'), client_name
ORDER BY city_name, order_date;
*/