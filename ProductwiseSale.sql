WITH tbl1 AS (
    SELECT m.id AS machine_id,m.registration_id as registrations_id, ct.name AS city_name, c.name AS client_name, m.machine_number AS machine_name
    FROM machines m
    JOIN cities ct ON m.city_id = ct.id
    JOIN clients c ON m.client_id = c.id
    WHERE  --m.client_id = $client_id-- and 
    m.id=$machine_id
    --and ct.id = $city_id
  
), 
tbl2 AS(
    SELECT 
    	date(o.created_at) as order_date,
    	   tbl1.city_name,
           tbl1.client_name,
           tbl1.machine_name,
           products.name AS product_name,
           products.price,
           op.product_quantity AS sold_quantity,
           --products.price * SUM(r.quantity) AS total_amount
           products.price * op.product_quantity AS total_amount
    FROM orders o  
    JOIN tbl1 ON o.registration_id = tbl1.registrations_id
    join orders_products op on o.id=op.order_id 
    JOIN products ON op.product_id = products.id
    WHERE --DATE(r.created_at)='20 24-08-28'
    o.dispensing ='completed' --or dispensing is null
    --o.dispensing ='started'
--      and  DATE(o.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
--      AND DATE(o.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
      and o.created_at >'2024-08-22 12:06:14.650'
	  and o.created_at <'2024-08-27 14:24:21.113'
      --AND r.machine_id = $machine_id
    GROUP BY o.created_at,
    		tbl1.city_name,
             tbl1.client_name,
             tbl1.machine_name,
             products.name,
             sold_quantity,
             total_amount,
             products.price
),
tbl3 as(
SELECT 	--tbl2.order_date,
		tbl2.city_name,
       tbl2.client_name,
       tbl2.machine_name,
       tbl2.product_name,
       tbl2.price,
       sum(tbl2.sold_quantity) as sold_quantity,
       sum(tbl2.total_amount) as total_amount
FROM tbl2
group by --tbl2.order_date,
tbl2.city_name,
       tbl2.client_name,
       tbl2.machine_name,
       tbl2.product_name,
       tbl2.price,
       tbl2.sold_quantity,
       tbl2.total_amount
       
       
UNION ALL

SELECT 	--order_date,
		'total' AS city_name,
       client_name,
       machine_name,
       product_name,
--       'all' AS product_name,
--       0 AS price,
       price,
       SUM(sold_quantity) AS sold_quantity,
       SUM(total_amount) AS total_amount
FROM tbl2
GROUP BY --tbl2.order_date,
tbl2.price,
tbl2.product_name,
client_name, machine_name

ORDER by city_name desc, product_name ASC       
)
select 
*
from tbl3
where city_name='total'
order by product_name asc


