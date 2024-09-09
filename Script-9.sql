WITH tbl1 AS (
    SELECT 
        m.id AS machine_id,
        p.id AS product_id,
        m.registration_id as registration_id,
        DATE(wp.updated_at) AS order_date,
        cities.name::VARCHAR AS city_name,
        clients.name::VARCHAR AS client_name,
        machine_number AS machine_name,
        w.name AS warehouse_name,
        w.warehouse_type,
        p.name::VARCHAR AS product_name,
        p.mrp AS product_price,
        wp.total_quantity,
        wp.total_quantity * p.mrp AS total_quantity_amount,
        wp.available_quantity,
        wp.available_quantity * p.mrp AS available_quantity_amount,
        wp.total_quantity - wp.available_quantity AS refill_quantity,
        (wp.total_quantity - wp.available_quantity) * p.mrp AS refill_quantity_amount
    FROM machines m
    JOIN cities ON m.city_id = cities.id
    JOIN clients ON m.client_id = clients.id
    JOIN warehouses w ON m.warehouse_id = w.id
    JOIN warehouses_products wp ON m.warehouse_id = wp.warehouse_id
    --join orders o on m.registration_id=o.registration_id
    JOIN products p ON wp.product_id = p.id
    WHERE cities.id = $city_id
	AND DATE(wp.updated_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
    AND DATE(wp.updated_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
    AND clients.id = $client_id
    -- AND m.id = $machine_id
    --AND p.id = $product_id

),
tbl2 AS (
    SELECT 
        tbl1.machine_id,
        tbl1.product_id,
        tbl1.order_date,
        tbl1.city_name,
        tbl1.client_name,
        tbl1.machine_name,
        tbl1.warehouse_name,
        tbl1.warehouse_type,
        tbl1.product_name,
        tbl1.product_price,
        tbl1.total_quantity,
        tbl1.total_quantity_amount,
        tbl1.available_quantity,
        tbl1.available_quantity_amount,
        tbl1.refill_quantity,
        tbl1.refill_quantity_amount,
        --SUM(op.product_quantity) AS sale_quantity,
        op.product_quantity AS sale_quantity,
        op.product_quantity * tbl1.product_price AS sale_amount,
        --op.id as op_id,
        --op.order_id,
        
        --sum(op.motor_number) as motor_number
        op.motor_number as motor_number
        
    FROM tbl1
    JOIN orders_products op ON tbl1.product_id = op.product_id
    join orders o on tbl1.registration_id=o.registration_id
    
    WHERE DATE(op.updated_at) = tbl1.order_date
    --and 
    --and op.product_quantity is not null
    GROUP BY 
        tbl1.machine_id,
        tbl1.product_id,
        tbl1.order_date,
        tbl1.city_name,
        tbl1.client_name,
        tbl1.machine_name,
        tbl1.warehouse_name,
        tbl1.warehouse_type,
        tbl1.product_name,
        tbl1.product_price,
        tbl1.total_quantity,
        tbl1.total_quantity_amount,
        tbl1.available_quantity,
        tbl1.available_quantity_amount,
        tbl1.refill_quantity,
        op.product_quantity,
        --op.id,
        op.motor_number,
        tbl1.refill_quantity_amount 
),

tbl3 As(
SELECT 
    machine_id,
    product_id,
    order_date,
    city_name,
    client_name,
    machine_name,
    warehouse_name,
    warehouse_type,
    product_name,
    product_price,
    total_quantity,
    total_quantity_amount,
    available_quantity,
    available_quantity_amount,
    refill_quantity,
    refill_quantity_amount,
    sale_quantity,
    --op_id,
    motor_number,
    sale_amount
FROM tbl2
)
select * from tbl3




