WITH tbl1 AS (
    SELECT registration_id
    FROM machines m
    WHERE m.city_id = 14
    AND m.client_id = 148
),
tbl2 AS (
    SELECT 
        o.*, opt.payment_mode, 
        ROW_NUMBER() OVER (PARTITION BY o.registration_id ORDER BY o.created_at) AS rn
    FROM orders o
    JOIN order_payment_types opt ON o.id = opt.order_id
    WHERE o.created_at BETWEEN '2024-07-26 00:00:00.000' AND '2024-07-29 23:59:59.000'
    AND o.registration_id IN (SELECT registration_id FROM tbl1)
    AND o.dispensing IS NOT null
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
tbl4 AS (
    SELECT 
        (SELECT instago_card_number 
         FROM wallets w 
         WHERE w.rfid = tbl3.last_non_null_rfid) AS order_instago_card_number, 
        tbl3.last_non_null_rfid AS order_rfid, 
        tbl3.order_guid,
        tbl3.payment_mode
    FROM tbl3
    WHERE tbl3.dispensing = 'completed'
    AND tbl3.rfid IS null
)
-- First query result
SELECT order_instago_card_number, order_rfid, order_guid 
FROM tbl4 
WHERE payment_mode LIKE '%rfid%'
AND payment_mode = 'rfid'

UNION ALL

-- Second query result
SELECT order_instago_card_number, order_rfid, order_guid 
FROM tbl4 
WHERE payment_mode IS null
AND order_rfid IS null;
