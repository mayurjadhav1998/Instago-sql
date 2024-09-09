WITH tbl1 AS (
    SELECT 
        s.id,
        m.machine_number AS machine_name,
        m.warehouse_id,
        s.updated_at AS days,
        s.tray_number,
        s.slot_number,
        s.capacity,
        p.name AS product_name,
        p.price AS product_price,
        s.product_id AS products_id,
        r.quantity AS refill_quantity,
        SUM(ps.current_quantity) AS current_quanti,
        SUM(ps.sold_quantity) AS sold_quanti,
        SUM(ps.added_quantity) AS added_quanti,
        SUM(ps.total_quantity) AS total_quanti,
        p.price * r.quantity AS refill_amount 
    FROM slots s
    JOIN machines m ON s.machine_id = m.id
    JOIN products p ON s.product_id = p.id
    JOIN refills r ON s.machine_id = r.machine_id AND s.product_id = r.product_id
    JOIN product_slots ps ON s.id = ps.slot_id AND s.product_id = ps.product_id
    WHERE 
        m.client_id = $client_id
        AND m.id = $machine_id and m.id =r.machine_id  and m.id =s.machine_id and s.id =ps.slot_id 
        and s.updated_at >='2024-08-13 11:54:55.190' and s.updated_at <='2024-08-14 12:49:45.314' 
        --AND DATE(s.updated_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD') AND DATE(s.updated_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
        
    GROUP BY s.id, m.id, p.id, r.id, ps.id
),
tbl2 AS (
    SELECT 
        tbl1.products_id,
        tbl1.machine_name,
        tbl1.warehouse_id,
        tbl1.days,
        tbl1.tray_number,
        tbl1.slot_number,
        tbl1.product_name,
        tbl1.product_price,
        tbl1.capacity,
        tbl1.current_quanti AS current_quantity,
        tbl1.sold_quanti AS sold_quantity,
        tbl1.added_quanti AS added_quantity,
        tbl1.total_quanti AS total_quantity,
        tbl1.refill_quantity,
        tbl1.refill_amount 

    FROM tbl1
)
--select * from tbl2
,
tbl3 AS (
    SELECT * FROM tbl2
    UNION ALL 
    SELECT 
        tbl1.products_id AS product_id,
        'all' as machine_name,
        tbl1.warehouse_id,
        tbl1.days,
        tbl1.tray_number,
        tbl1.slot_number,
        tbl1.product_name,
        tbl1.product_price,
        tbl1.capacity,
        SUM(tbl1.current_quanti) AS current_quantity,
        SUM(tbl1.sold_quanti) AS sold_quantity,
        SUM(tbl1.added_quanti) AS added_quantity,
        SUM(tbl1.total_quanti) AS total_quantity,
        SUM(tbl1.refill_quantity) AS refill_quantity,
        SUM(tbl1.refill_amount) AS refill_amount

    FROM tbl1
    GROUP BY tbl1.products_id, tbl1.machine_name, tbl1.warehouse_id, tbl1.days, tbl1.tray_number, tbl1.slot_number, tbl1.product_name, tbl1.product_price, tbl1.capacity
)
SELECT * FROM tbl3;
