WITH tbl2 AS (
    SELECT 
        m.id AS machine_id,
        cities.name::VARCHAR AS branch,
        clients.name::VARCHAR AS client,
        machine_number AS machine_name,
        machine_serial_number,
        opt.payment_mode AS payment_mode,
        TO_CHAR(DATE(orders.updated_at), 'YYYY-MM-DD')::TEXT AS order_date,
        SUM(CASE WHEN payment_mode = 'rfid' THEN payment_amount ELSE 0 END) AS RFID,
        SUM(CASE WHEN payment_mode = 'upi' THEN payment_amount ELSE 0 END) AS UPI,
        SUM(CASE WHEN payment_mode = 'cash' THEN payment_amount ELSE 0 END) AS Cash,
        SUM(CASE WHEN payment_mode = 'jiopay' THEN payment_amount ELSE 0 END) AS Jiopay,
        SUM(CASE WHEN payment_mode = 'instago_wallet' THEN payment_amount ELSE 0 END) AS Instago_Wallet,
        SUM(payment_amount) AS Total_Sale
    FROM machines m
    JOIN cities ON m.city_id = cities.id
    JOIN clients ON m.client_id = clients.id
    JOIN orders ON m.registration_id = orders.registration_id
    JOIN order_payment_types opt ON orders.id = opt.order_id
    WHERE --m.id and
    m.client_id=$client_id and
       -- m.id = $machine_id and
         DATE(orders.created_at) = DATE(opt.created_at)
        AND orders.dispensing = 'completed' 
        AND DATE(orders.updated_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
        AND DATE(orders.updated_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
    GROUP BY 
        m.id, 
        cities.name, 
        clients.name,
        machine_number, 
        machine_serial_number,
        opt.payment_mode,
        TO_CHAR(DATE(orders.updated_at), 'YYYY-MM-DD')
),
tbl3 AS (
    SELECT * FROM tbl2
    UNION ALL
    SELECT 
        machine_id,
        'total' AS branch,
        client,
        machine_name,
        machine_serial_number,
        'all' AS payment_mode,
        order_date,
        SUM(RFID) AS RFID,
        SUM(UPI) AS UPI,
        SUM(Cash) AS Cash,
		SUM(jiopay) AS Jiopay,
        SUM(Instago_Wallet) AS Instago_Wallet,
        SUM(Total_Sale) AS Total_Sale
    FROM tbl2
    GROUP BY 
        machine_id,
        client,
        machine_name,
        machine_serial_number,
        order_date
    ORDER BY branch DESC
),
tbl4 AS (
    SELECT 
        machine_id,
        'total' AS branch,
        client,
        machine_name,
        machine_serial_number,
        'all' AS payment_mode,
        UPPER(TO_CHAR(DATE_TRUNC('month', DATE(order_date)), 'YYYY-Mon'))::TEXT AS order_date,
        SUM(RFID)/2 AS RFID,
        SUM(UPI)/2 AS UPI,
        SUM(Cash)/2 AS Cash,
		SUM(jiopay)/2 AS Jiopay,
        SUM(Instago_Wallet)/2 AS Instago_Wallet,
        SUM(Total_Sale)/2 AS Total_Sale
    FROM tbl3
    GROUP BY 
        machine_id,
        client,
        machine_name,
        machine_serial_number,
        UPPER(TO_CHAR(DATE_TRUNC('month', DATE(order_date)), 'YYYY-Mon'))
)
--select * from TBl2
--SELECT * FROM tbl3;
--
SELECT * FROM tbl4;
