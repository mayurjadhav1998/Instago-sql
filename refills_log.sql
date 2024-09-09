/*
WITH refiils_log AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
        DATE(refills.created_at) AS order_date,
        clients.name::VARCHAR AS client_name,
        products.name::varchar as product_name,
        products.mrp :: integer as products_mrp,
        refills.quantity as refills_quantity,
        users.id as operator_id,
        users.name as operator_name,
        (products.mrp * refills.quantity) as total_product_amount
    FROM refills
    JOIN machines ON refills.machine_id = machines.id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    join products on refills.product_id =products.id
    join users on refills.user_id =users.id
    WHERE cities.id = $city_id
    AND clients.id = $client_id
AND DATE(refills.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')0
AND DATE(refills.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
    GROUP BY cities.name, DATE(refills.created_at), clients.name,operator_id,operator_name,product_name,products_mrp,refills_quantity,total_product_amount
)
SELECT * FROM refiils_log;
*/


--total_refills with sum of all data

WITH refiils_log AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
        DATE(refills.created_at) AS order_date,
        refills.updated_at as refill_time,
        clients.name::VARCHAR AS client_name,
        machines.machine_number as machine_name,
        products.name::VARCHAR AS product_name,
        products.mrp::INTEGER AS products_mrp,
        refills.quantity AS refills_quantity,
     
        users.id AS operator_id,
        users.name AS operator_name,
        (products.mrp * refills.quantity) AS total_product_amount
    FROM refills
    JOIN machines ON refills.machine_id = machines.id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    JOIN products ON refills.product_id = products.id
    JOIN users ON refills.user_id = users.id 
    WHERE --cities.id = $city_id and
    -- clients.id = $client_id
    
    
     machines.id =$machine_id
    and  refills.created_at>='2024-08-22 12:06:00.256'
	and  refills.created_at<='2024-08-22 12:06:15.650'

--    AND DATE(refills.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
--    AND DATE(refills.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
    GROUP BY cities.name, DATE(refills.created_at),refills.updated_at, clients.name,machines.machine_number, operator_id, operator_name, product_name, products_mrp, refills_quantity, total_product_amount 
    ORDER BY order_date desc,refill_time DESC, city_name

)
SELECT *
FROM refiils_log

UNION ALL

SELECT
    'Total' AS city_name,
    order_date AS order_date,
    refill_time,
    client_name AS client_name,
    machine_name,
    --'All' AS product_name,
    product_name,
    sum(products_mrp) AS products_mrp,
    SUM(refills_quantity) AS refills_quantity,
    
    operator_id AS operator_id,
    operator_name AS operator_name,
    SUM(total_product_amount) AS total_product_amount
FROM refiils_log
group by order_date,
	refiils_log.refill_time,
	refiils_log.product_name,
	client_name,
	refiils_log.machine_name,
	operator_id,
	operator_name
ORDER BY city_name desc;

