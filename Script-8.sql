with tbl1 as (
select m.id  as machine_id,
p.id as product_id,
m.registration_id as registration_id,
        DATE(wp.updated_at) AS order_date,
		cities.name::VARCHAR AS city_name,
        clients.name::VARCHAR AS client_name,
	    machine_number as machine_name,
        w.name as warehouse_name,
        w.warehouse_type,
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
    --and m.id=$machine_id
    and product_id=$product_id
    AND DATE(wp.updated_at ) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
    AND DATE(wp.updated_at ) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
)
--select * from tbl1
,
tbl2 as(
select tbl1.*, op.id as orders_product_id,
	sum(op.product_quantity) as sale_quantity,
	product_quantity *product_price as sale_amount

from tbl1
join orders_products op on tbl1.product_id=op.product_id
where DATE(op.updated_at)=tbl1.order_date
group by machine_id,
		tbl1.product_id,
		registration_id,
		order_date,
		city_name,
		client_name,
		machine_name,
		warehouse_name,
		warehouse_type,
		product_name,
		product_price,
		total_quantity,total_quantity_amount,
		available_quantity,available_quantity_amount,
		refill_quantity
		, refill_quantity_amount
		,orders_product_id 
)
--select * from tbl2
,
tbl3 as(select 	tbl1.*,tbl1.machine_id,
		tbl1.product_id,
		tbl1.registration_id,
		tbl1.order_date,
		tbl1.city_name,
		tbl1.client_name,
		tbl1.machine_name,
		tbl1.warehouse_name,
		tbl1.warehouse_type,
		tbl1.product_name,
		tbl1.product_price,
		tbl1.total_quantity,tbl1.total_quantity_amount,
		tbl1.available_quantity,tbl1.available_quantity_amount,
		tbl1.refill_quantity,tbl1.refill_quantity_amount,orders_product_id
		,motor_number,sale_quantity,sale_amount
		from tbl2       )
select * from tbl3





/*
tbl3 as(select 	*,tbl1.machine_id,
		tbl1.product_id,
		tbl1.registration_id,
		tbl1.order_date,
		tbl1.city_name,
		tbl1.client_name,
		tbl1.machine_name,
		tbl1.warehouse_name,
		tbl1.warehouse_type,
		tbl1.product_name,
		tbl1.product_price,
		tbl1.total_quantity,tbl1.total_quantity_amount,
		tbl1.available_quantity,tbl1.available_quantity_amount,
		tbl1.refill_quantity,tbl1.refill_quantity_amount,orders_product_id
		,motor_number,sale_quantity,sale_amount
		from tbl2)
select * from tbl3
*/



