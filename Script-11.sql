WITH tbl1 AS (
    SELECT 
        machine_number AS machine_name,
        m.warehouse_id,
        o.updated_at AS days,
        s.tray_number,
        s.slot_number,
        s.capacity,
        p.name AS product_name,
        p.price AS product_price,
        s.product_id AS products_id,
        r.quantity AS refill_quantity,
        motor_number,op.product_quantity as sold_quantity,
        SUM(ps.current_quantity) AS current_quanti,SUM(ps.sold_quantity) AS sold_quanti,SUM(ps.added_quantity) AS added_quanti,sUM(ps.total_quantity) AS total_quanti,
        p.price * r.quantity AS refill_amount 
    FROM machines m
    JOIN slots s ON m.id = s.machine_id
    join orders o on m.registration_id=o.registration_id
    join orders_products op on o.id=op.order_id
    JOIN products p ON s.product_id = p.id
    JOIN product_slots ps ON s.id = ps.slot_id AND s.product_id = ps.product_id
    JOIN refills r ON s.machine_id = r.machine_id AND s.product_id = r.product_id
    
    WHERE m.id=$machine_id
        --m.client_id = $client_id
    and motor_number=$motor_number
        AND m.id = $machine_id and m.id =r.machine_id  and m.id =s.machine_id and s.id =ps.slot_id 
        and o.updated_at >='2024-08-13 11:54:55.190' and o.updated_at <='2024-08-14 12:49:45.314' 
       group by m.machine_number,m.warehouse_id,o.updated_at,s.tray_number,s.slot_number,s.capacity, p.name,
        p.price ,
        s.product_id ,
        r.quantity ,motor_number,
        ps.current_quantity,ps.sold_quantity,
        ps.added_quantity,ps.total_quantity,
        op.product_quantity
        
       
       )
        
        select 
        tbl1.machine_name,tbl1.warehouse_id,tbl1.days, tbl1.capacity, tbl1.product_name,
        tbl1.product_price ,
--        tbl1.product_id ,
        tbl1.refill_quantity ,tbl1.motor_number,
        tbl1.current_quanti,tbl1.sold_quanti,
        tbl1.added_quanti,tbl1.total_quanti,
        tbl1.refill_quantity
        
        from tbl1
        
        
        
        
        