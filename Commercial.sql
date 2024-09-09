WITH tbl2 AS (
    SELECT 
        m.id AS machine_id,
        cities.name::VARCHAR AS branch,
        clients.name::VARCHAR AS client,
        users.name as operator_name,
        machine_number AS machine_name,
        machine_serial_number,
        opt.payment_mode AS payment_mode,
        TO_CHAR(DATE(cash_infos.updated_at), 'YYYY-MM-DD')::TEXT AS cash_collected_date,
        max(cash_infos.collected_cash) AS cash_collected,
        SUM(cash_infos.submitted_cash) AS cash_submitted,
        SUM(CASE WHEN payment_mode = 'rfid' THEN payment_amount ELSE 0 END) AS RFID,
        SUM(CASE WHEN payment_mode = 'upi' THEN payment_amount ELSE 0 END) AS UPI,
        SUM(CASE WHEN payment_mode = 'cash' THEN payment_amount ELSE 0 END) AS Cash,
        SUM(CASE WHEN payment_mode = 'instago_wallet' THEN payment_amount ELSE 0 END) AS Instago_Wallet,
        SUM(payment_amount) AS Total_Sale
    FROM machines m
    JOIN cities ON m.city_id = cities.id
    JOIN clients ON m.client_id = clients.id
    JOIN cash_infos ON m.id = cash_infos.machine_id
    join users on cash_infos.user_id =users.id
    JOIN orders ON m.registration_id = orders.registration_id
    JOIN order_payment_types opt ON orders.id = opt.order_id
    WHERE m.client_id=$client_id--m.id and
        --and m.id = $machine_id and
        and  DATE(cash_infos.created_at) = DATE(opt.created_at)
        AND orders.dispensing = 'completed' 
        AND DATE(cash_infos.updated_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
        AND DATE(cash_infos.updated_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
    GROUP BY 
        m.id, 
        cities.name, 
        clients.name,
        users.name,
        machine_number, 
        machine_serial_number,
        opt.payment_mode,
        TO_CHAR(DATE(cash_infos.updated_at), 'YYYY-MM-DD')
),
tbl3 AS (
    SELECT * FROM tbl2
    UNION ALL
    SELECT 
        machine_id,
        'total' AS branch,
        client,
        operator_name,
        machine_name,
        machine_serial_number,
        'all' AS payment_mode,
        cash_collected_date,
        SUM(cash_collected) AS cash_collected,
        SUM(cash_submitted) AS cash_submitted,
        SUM(RFID) AS RFID,
        SUM(UPI) AS UPI,
        SUM(Cash) AS Cash,
        SUM(Instago_Wallet) AS Instago_Wallet,
        SUM(Total_Sale) AS Total_Sale
    FROM tbl2
    GROUP BY 
        machine_id,
        client,
        operator_name,
        machine_name,
        machine_serial_number,
        cash_collected_date
    ORDER BY branch DESC
),
tbl4 AS (
    SELECT 
        machine_id,
        'total' AS branch,
        client,
        operator_name,
        machine_name,
        machine_serial_number,
        'all' AS payment_mode,
        UPPER(TO_CHAR(DATE_TRUNC('month', DATE(cash_collected_date)), 'YYYY-Mon'))::TEXT AS cash_collected_date,
        SUM(cash_collected)/2 AS cash_collected,
        SUM(cash_submitted)/2 AS cash_submitted,
        SUM(RFID)/2 AS RFID,
        SUM(UPI)/2 AS UPI,
        SUM(Cash)/2 AS Cash,
        SUM(Instago_Wallet)/2 AS Instago_Wallet,
        SUM(Total_Sale)/2 AS Total_Sale
    FROM tbl3
    GROUP BY 
        machine_id,
        client,
        operator_name,
        machine_name,
        machine_serial_number,
        UPPER(TO_CHAR(DATE_TRUNC('month', DATE(cash_collected_date)), 'YYYY-Mon'))
)
--SELECT * FROM tbl3;
--
SELECT * FROM tbl4;
