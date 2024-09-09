WITH tbl1 AS (
    SELECT m.id AS machine_id, ct.name AS city_name, c.name AS client_name, m.machine_number AS machine_name
    FROM machines m
    JOIN cities ct ON m.city_id = ct.id
    JOIN clients c ON m.client_id = c.id
    WHERE  m.client_id = $client_id
    --and ct.id = $city_id
    
      
),
tbl2 AS (
    SELECT tbl1.city_name,
           tbl1.client_name,
           tbl1.machine_name,
           products.name AS product_name,
           products.price,
           r.quantity AS total_quantity,
           --products.price * SUM(r.quantity) AS total_amount
           products.price * r.quantity AS total_amount

    FROM refills r 
    JOIN products ON r.product_id = products.id
    JOIN slots ON r.product_id = slots.product_id 
    JOIN machines ON r.machine_id = machines.id 
    JOIN tbl1 ON r.machine_id = tbl1.machine_id
    WHERE --DATE(r.created_at)='2024-08-28'
          DATE(r.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
      AND DATE(r.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
      --AND r.machine_id = $machine_id
    GROUP BY tbl1.city_name,
             tbl1.client_name,
             tbl1.machine_name,
             products.name,
             total_quantity,
             total_amount,
             products.price
)

SELECT tbl2.city_name,
       tbl2.client_name,
       tbl2.machine_name,
       tbl2.product_name,
       tbl2.price,
       sum(tbl2.total_quantity) as total_quantity,
       sum(tbl2.total_amount) as total_amount
FROM tbl2
group by 
tbl2.city_name,
       tbl2.client_name,
       tbl2.machine_name,
       tbl2.product_name,
       tbl2.price,
       tbl2.total_quantity,
       tbl2.total_amount
       
       
UNION ALL

SELECT 'total' AS city_name,
       client_name,
       machine_name,
       'all' AS product_name,
       0 AS price,
       SUM(total_quantity) AS total_quantity,
       SUM(total_amount) AS total_amount
FROM tbl2
GROUP BY client_name, machine_name

ORDER BY product_name ASC;       
       



