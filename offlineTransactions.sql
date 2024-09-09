WITH tbl1 AS (
    SELECT 
        m.id AS machine_id,
        m.registration_id as registrations_id, 
        ct.name AS city_name, 
        c.name AS client_name, 
        m.machine_number AS machine_name
    FROM machines m
    JOIN cities ct ON m.city_id = ct.id
    JOIN clients c ON m.client_id = c.id
    WHERE m.id=$machine_id
),
tbl2 AS (
    SELECT 
        date(sr.created_at) as order_date,
        tbl1.city_name,
        tbl1.client_name,
        tbl1.machine_name,
        parameter_details,
        response,
        request_status,
        opt.payment_amount,
        -- Check if 'sync: offline' is present in parameter_details
        CASE 
            WHEN parameter_details LIKE '%sync: offline%' THEN 1 
            ELSE 0 
        END AS offline_count,
        -- Determine offline time
        CASE 
            WHEN parameter_details LIKE '%sync: offline%' THEN TO_CHAR(sr.created_at, 'HH24:MI:SS.MS')
            ELSE NULL
        END AS offline_time
    FROM service_requests sr   
    JOIN tbl1 ON sr.registration_id = tbl1.registrations_id
    JOIN orders o ON sr.order_guid = o.order_guid 
    JOIN order_payment_types opt ON o.id = opt.order_id 
    WHERE action = 'sales_updates_to_server'
    AND request_status = 'completed'
    AND DATE(sr.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
    AND DATE(sr.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
    AND o.dispensing = 'completed'
    GROUP BY 
        sr.created_at,
        sr.parameter_details,
        sr.response,
        sr.request_status,
        opt.payment_amount,
        tbl1.city_name,
        tbl1.client_name,
        tbl1.machine_name
)
SELECT * 
FROM tbl2;
