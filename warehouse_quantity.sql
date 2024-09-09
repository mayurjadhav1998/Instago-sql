with tbl1 as (
select --m.id  as machine_id,
        DATE(wp.updated_at) AS order_date,
		cities.name::VARCHAR AS city_name,
        clients.name::VARCHAR AS client_name,
        m.id  as machine_id,
	    machine_number as machine_name,
        w.name as warehouse_name,
        w.warehouse_type,
        p.id as product_id,
        p.name::VARCHAR AS product_name,
        p.mrp as product_price,
        wp.total_quantity,
        wp.total_quantity* p.mrp as total_quantity_amount,
        wp.available_quantity,
        wp.available_quantity* p.mrp as available_quantity_amount,
        wp.total_quantity-wp.available_quantity as refill_quantity,
        (wp.total_quantity-wp.available_quantity)* p.mrp as refill_quantity_amount

        

from machines m
JOIN cities ON m.city_id = cities.id
    JOIN clients ON m.client_id = clients.id
    join warehouses w on m.warehouse_id =w.id 
    join warehouses_products wp on m.warehouse_id =wp.warehouse_id  
    join products p on wp.product_id=p.id
    WHERE cities.id = $city_id
    AND clients.id = $client_id
    and m.id=$machine_id
    AND DATE(wp.updated_at ) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
    AND DATE(wp.updated_at ) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
)




select * from tbl1
 union all

SELECT
    order_date as order_date,
    'Total' AS city_name,
    client_name AS client_name,
    machine_id,
    machine_name,
    warehouse_name,
    warehouse_type,
    product_id,
    'All' AS product_name,
    '0' as product_price,
    --sum(products_mrp) AS products_mrp,
    SUM(total_quantity) AS total_quantity,
    sum(total_quantity_amount) as total_quantity_amount,
    SUM(available_quantity) AS available_quantity,
    sum(available_quantity_amount) as available_quantity_amount,
    SUM(refill_quantity) AS refill_quantity,
    sum(refill_quantity_amount) as refill_quantity_amount
    --operator_id AS operator_id,
    --operator_name AS operator_name,
    --
    
    --SUM(total_product_amount) AS total_product_amount
FROM tbl1
group by tbl1.order_date,
tbl1.machine_id,
tbl1.product_id,
	client_name,
	machine_name,
	warehouse_name,
    warehouse_type
ORDER BY city_name desc;