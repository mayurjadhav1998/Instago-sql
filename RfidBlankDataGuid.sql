WITH tbl1 AS (
    SELECT registration_id
    FROM machines m
    WHERE --m.city_id= $city_id  and
    m.client_id =$client_id --95 or m.client_id=108 or m.client_id=129 or m.client_id=208
),
tbl2 AS (
    SELECT 
        o.*, opt.payment_mode, 
        ROW_NUMBER() OVER (PARTITION BY o.registration_id ORDER BY o.created_at) AS rn
    FROM orders o
    JOIN order_payment_types opt ON o.id = opt.order_id
    WHERE --o.created_at BETWEEN '2024-08-02 00:00:00.000' AND '2024-08-15 23:59:59.000'
     DATE(o.created_at) >='2024-08-01' --$start_date --'2024-06-01'
    AND DATE(o.created_at) <='2024-08-20' --$end_date --'2024-06-30'
    AND o.registration_id IN (SELECT registration_id FROM tbl1)
    AND o.dispensing IS NOT null
   -- and opt.payment_mode like '%rfid%' --cmt for data 1 and uncmt for data 2
    --and opt.payment_mode = 'rfid'
),
tbl3 AS (
    SELECT 
        t1.*,
        COALESCE(
            t1.rfid, 
            (
                SELECT rfid
                FROM tbl2 t2
                WHERE t2.registration_id = t1.registration_id
                AND t2.rn < t1.rn
                AND t2.rfid IS NOT NULL
                ORDER BY t2.created_at DESC
                LIMIT 1
            )
        ) AS last_non_null_rfid
    FROM tbl2 t1
    ORDER BY registration_id, created_at DESC
),
--SELECT * FROM tbl3
--ORDER BY registration_id, created_at DESC;

tbl4 AS (
    select (select instago_card_number from wallets w where w.rfid = tbl3.last_non_null_rfid) as order_instago_card_number, tbl3.last_non_null_rfid as order_rfid, tbl3.order_guid FROM tbl3
    where tbl3.dispensing = 'completed'
    AND tbl3.rfid IS null
    and tbl3.payment_mode is null --uncmt for data 1 and cmt for data 2
)
select * from tbl4
