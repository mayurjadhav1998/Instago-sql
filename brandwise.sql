WITH tbl1 AS (
    SELECT m.id AS machine_id, m.registration_id as registrations_id, ct.name AS city_name, 
           c.name AS client_name, m.machine_number AS machine_name
    FROM machines m
    JOIN cities ct ON m.city_id = ct.id
    JOIN clients c ON m.client_id = c.id
    WHERE m.client_id = $client_id --and
    --m.city_id=11
    
), 
tbl2 AS (
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
        products.price * op.product_quantity AS total_amount
    FROM orders o  
    JOIN tbl1 ON o.registration_id = tbl1.registrations_id
    JOIN orders_products op ON o.id = op.order_id 
    JOIN products ON op.product_id = products.id
    JOIN brands b ON products.brand_id = b.id
    JOIN categories c ON products.category_id = c.id
    WHERE 
        o.dispensing = 'completed' and  
        DATE(o.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
        AND DATE(o.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
    GROUP BY o.created_at,
             tbl1.city_name,
             tbl1.client_name,
             tbl1.machine_name,
             b.name,
             c.name,
             products.name,
             products.price,
             op.product_quantity
),
tbl3 AS (
    SELECT 
        tbl2.brand,
        SUM(tbl2.total_amount) AS total_amount
    FROM tbl2
    GROUP BY tbl2.brand
),
tbl4 AS (
    SELECT 
        'total' AS brand,
        SUM(total_amount) AS total_amount
    FROM tbl3
)
SELECT * FROM tbl3
UNION ALL
SELECT * FROM tbl4
ORDER BY total_amount DESC;
