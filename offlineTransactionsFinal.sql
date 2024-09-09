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
    WHERE --m.client_id=$client_id --and 
    --m.id = $machine_id
    m.id in(363
--387
--389
--391
--364
--359
--360
--361
--388
--392
--390
--362 
)
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
        CASE 
            WHEN parameter_details LIKE '%sync: offline%' THEN 1 
            ELSE 0 
        END AS offline_count,
        CASE 
            WHEN parameter_details LIKE '%sync: offline%' THEN TO_CHAR(sr.created_at, 'HH12:MI:SS.MS AM')
            ELSE NULL
        END AS offline_time,
        sr.created_at
    FROM service_requests sr   
    JOIN tbl1 ON sr.registration_id = tbl1.registrations_id
    JOIN orders o ON sr.order_guid = o.order_guid 
    JOIN orders_products op ON o.id = op.order_id
    WHERE action = 'sales_updates_to_server'
    AND request_status = 'started'
    --AND DATE(sr.created_at) =$start_date 
    AND DATE(sr.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
    AND DATE(sr.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
    --AND o.dispensing = 'completed'
    GROUP BY 
        sr.created_at,
        sr.parameter_details,
        sr.response,
        sr.request_status,
        tbl1.city_name,
        tbl1.client_name,
        tbl1.machine_name
),
offline_summary AS (
    SELECT 
        order_date,
        city_name,
        client_name,
        machine_name,
        request_status,
        MIN(CASE WHEN offline_count = 1 THEN offline_time END) AS first_offline_time,
        MAX(CASE WHEN offline_count = 1 THEN offline_time END) AS last_offline_time,
        SUM(offline_count) AS total_offline_count
    FROM tbl2
    WHERE offline_count = 1
    GROUP BY 
        order_date,
        city_name,
        client_name,
        machine_name,
        request_status
)
SELECT 
    order_date,
    city_name,
    client_name,
    machine_name,
    request_status,
    total_offline_count AS offline_count,
    first_offline_time,
    last_offline_time
FROM offline_summary
ORDER BY order_date, first_offline_time;
