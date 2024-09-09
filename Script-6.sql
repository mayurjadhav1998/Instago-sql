WITH tbl1 AS (
    SELECT m.id AS machine_id,
    --w.name,
    ct.name AS city_name, c.name AS client_name, m.machine_number AS machine_name
    FROM machines m
    JOIN cities ct ON m.city_id = ct.id
   -- JOIN warehouses w ON m.warehouse_id = w.id
    JOIN clients c ON m.client_id = c.id
    
    
    WHERE ct.id = $city_id
      AND m.client_id = $client_id
      AND m.id = $machine_id
      --and DATE(o.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
      --AND DATE(o.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
      
)
--select * from tbl1
,
tbl2 AS (
    SELECT tbl1.city_name,
           tbl1.client_name,
           tbl1.machine_name,
           products.name AS product_name,
           products.price,
           
           r.quantity AS total_quantity,
           --products.price * SUM(r.quantity) AS total_amount
           products.price * r.quantity AS total_amount,
           opt.payment_amount as order_value,
           o.id as order_id

    FROM refills r 
    JOIN products ON r.product_id = products.id
    --JOIN slots ON r.product_id = slots.product_id 
    JOIN machines ON r.machine_id = machines.id 
    JOIN tbl1 ON r.machine_id = tbl1.machine_id
    JOIN orders o ON machines.registration_id=o.registration_id
    JOIN order_payment_types opt ON o.id = opt.order_id
    --join orders_products op on o.id =op.product_id
    WHERE DATE(r.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
      AND DATE(r.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
      
    GROUP BY tbl1.city_name,
             tbl1.client_name,
             tbl1.machine_name,
             products.name,
             total_quantity,
             total_amount,
             products.price,
             opt.payment_amount
             
)
--select * from tbl2
,
tbl3 as (
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
)
--select * from tbl3
,


















tbls as(
SELECT m.id AS machine_id,
           --w.name AS warehouse_name,
           ct.name AS city_name,
           c.name AS client_name,
           m.machine_number AS machine_name,
           opt.payment_amount
    FROM machines m
    JOIN cities ct ON m.city_id = ct.id
   -- JOIN warehouses w ON m.warehouse_id = w.id
    JOIN clients c ON m.client_id = c.id
    join tbl3 on m.machine_number=tbl2.machine_name
    JOIN orders o ON m.registration_id=o.registration_id
    JOIN order_payment_types opt ON o.id = opt.order_id
    join orders_products op on o.id =op.product_id
	
    
    WHERE o.dispensing = 'completed'
    /*	
    and  ct.id = $city_id
          AND m.client_id = $client_id*/
          and m.id=$machine_id
          and DATE(o.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
          AND DATE(o.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
)
select * from tbls







/*
,


tbls2 AS (
    SELECT tbls.city_name,
           tbls.client_name,
           tbls.machine_name,
           p.name AS product_name,
           p.price,
           --r.id  as refill_id,
           p.id as product_id,
          CAST(r.quantity AS INTEGER) AS total_quantity,
           p.price * CAST(r.quantity AS INT) AS total_amount
    FROM products p
    JOIN refills r ON p.id = r.product_id
    JOIN slots ON p.id = slots.product_id
    JOIN machines ON r.machine_id = machines.id
    JOIN tbls ON r.machine_id = tbls.machine_id


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
    WHERE orders.dispensing != 'completed'
      AND cities.id = $1
      AND DATE(orders.created_at) = $2
      AND clients.id = $3
    GROUP BY cities.name, DATE(orders.created_at), clients.name
)
--,
SELECT * FROM city_sales;*/
