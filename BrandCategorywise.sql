 WITH tbl1 AS (
    SELECT m.id AS machine_id,m.registration_id as registrations_id, ct.name AS city_name, c.name AS client_name, m.machine_number AS machine_name
    FROM machines m
    JOIN cities ct ON m.city_id = ct.id
    JOIN clients c ON m.client_id = c.id
    WHERE  m.client_id = $client_id-- and 
    --m.id=$machine_id
    --and ct.id = $city_id
  
), 
tbl2 AS(
    SELECT 
    	date(o.created_at) as order_date,
    	   tbl1.city_name,
           tbl1.client_name,
           tbl1.machine_name,
           c.name as category,
           b.name as brand,
           products.name AS product_name,
           products.price,
           op.product_quantity AS total_quantity,
           --products.price * SUM(r.quantity) AS total_amount
           products.price * op.product_quantity AS total_amount
    FROM orders o  
    JOIN tbl1 ON o.registration_id = tbl1.registrations_id
    join orders_products op on o.id=op.order_id 
    JOIN products ON op.product_id = products.id
    join brands b on products.brand_id =b.id
    join categories c on products.category_id = c.id
    WHERE --DATE(r.created_at)='20 24-08-28'
    --o.dispensing ='completed' and --or dispensing is null
    --o.dispensing ='started'
        DATE(o.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
      AND DATE(o.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
      --AND r.machine_id = $machine_id
    GROUP BY o.created_at,
    		tbl1.city_name,
             tbl1.client_name,
             tbl1.machine_name,
             b.name,
             c.name,
             products.name,
             total_quantity,
             total_amount,
             products.price
),
tbl3 as(
SELECT 	--tbl2.order_date,
		tbl2.city_name,
       tbl2.client_name,
       tbl2.machine_name,
       tbl2.category,
       tbl2.brand,
       tbl2.product_name,
       tbl2.price,
       sum(tbl2.total_quantity) as total_quantity,
       sum(tbl2.total_amount) as total_amount
FROM tbl2
group by --tbl2.order_date,
tbl2.city_name,
       tbl2.client_name,
       tbl2.machine_name,
       tbl2.category,
       tbl2.brand,
       tbl2.product_name,
       tbl2.price,
       tbl2.total_quantity,
       tbl2.total_amount
       
       
UNION ALL

SELECT 	--order_date,
		'total' AS city_name,
       client_name,
       machine_name,
	   --category,brand,
	   max(category) as category, max(brand) as brand,
       product_name,
--       'all' AS product_name,
--       0 AS price,
       price,
       SUM(total_quantity) AS total_quantity,
       SUM(total_amount) AS total_amount
FROM tbl2
GROUP BY --tbl2.order_date,
tbl2.price,
tbl2.category,tbl2.brand,
tbl2.product_name,
client_name, machine_name

ORDER by city_name desc, product_name ASC       
)
select 
*
from tbl3
order by product_name asc


