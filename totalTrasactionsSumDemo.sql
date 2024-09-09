WITH completed_orders AS (
    SELECT DISTINCT order_guid
    FROM orders
    JOIN machines ON orders.registration_id = machines.registration_id
    WHERE dispensing = 'completed'
    and machines.id=$machine_id
    --AND machines.client_id = 243
    AND DATE(orders.created_at) >=$start_date --'2024-06-01'
    AND DATE(orders.created_at) <=$end_date --'2024-06-30'
)
--select * from completed_orders
,
order_status AS (
    SELECT 
        orders.order_guid,
        MAX(orders.dispensing) AS max_dispensing_status,
        SUM(order_payment_types.payment_amount) AS total_payment
    FROM orders
    JOIN order_payment_types ON orders.id = order_payment_types.order_id
    WHERE orders.dispensing IS NOT NULL
    AND DATE(orders.created_at) >=$start_date --'2024-06-01'
    AND DATE(orders.created_at) <=$end_date --'2024-06-30'
    GROUP BY orders.order_guid
),
unique_order_status AS (
    SELECT 
        order_guid,
        MAX(max_dispensing_status) AS max_dispensing_status,
        SUM(total_payment) AS total_payment
    FROM order_status
    GROUP BY order_guid
),
sales_data AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
        DATE(orders.created_at)::TEXT AS order_date,
        clients.name::VARCHAR AS client_name,
        SUM(CASE 
            WHEN uos.max_dispensing_status != 'completed' AND uos.order_guid NOT IN (select distinct order_guid FROM completed_orders) THEN uos.total_payment ELSE 0 END
        ) AS total_loss,
        COUNT(CASE 
            WHEN uos.max_dispensing_status != 'completed' AND uos.order_guid NOT IN (SELECT order_guid FROM completed_orders) THEN 1 ELSE NULL END
        ) AS total_failed_transactions,
        SUM(CASE 
            WHEN uos.max_dispensing_status = 'completed' THEN uos.total_payment  ELSE 0 END
        ) AS total_sale,
        COUNT(CASE 
            WHEN uos.max_dispensing_status = 'completed' THEN 1 ELSE NULL END
        ) AS total_completed_transactions
    FROM orders
    JOIN unique_order_status uos ON orders.order_guid = uos.order_guid
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    where -- cities.id = 11 -- $city_id
     machines.id=$machine_id

      --AND clients.id = 243 -- $client_id -- Uncomment for custom input client_id
    GROUP BY cities.name, DATE(orders.created_at), clients.name
),
monthly_totals AS (
    SELECT
        'Total' AS city_name,
        UPPER(TO_CHAR(DATE_TRUNC('month', DATE(sd.order_date)), 'YYYY-Mon')) AS order_date,
        sd.client_name,
        SUM(sd.total_loss) AS total_loss,
        SUM(sd.total_failed_transactions) AS total_failed_transactions,
        SUM(sd.total_sale) AS total_sale,
        SUM(sd.total_completed_transactions) AS total_completed_transactions,
        SUM(sd.total_failed_transactions) + SUM(sd.total_completed_transactions) AS total_transactions
    FROM sales_data sd
    GROUP BY UPPER(TO_CHAR(DATE_TRUNC('month', DATE(sd.order_date)), 'YYYY-Mon')), sd.client_name
),
final_result AS (
    SELECT 
        sd.city_name, 
        sd.order_date, 
        sd.client_name, 
        sd.total_loss, 
        sd.total_sale,
        sd.total_failed_transactions,
        sd.total_completed_transactions
    FROM sales_data sd
    UNION ALL
    SELECT 
        mt.city_name, 
        mt.order_date, 
        mt.client_name, 
        mt.total_loss, 
        mt.total_sale,
        mt.total_failed_transactions,
        mt.total_completed_transactions
    FROM monthly_totals mt
)
--select * from sales_data
SELECT 
    fr.city_name, 
    fr.order_date, 
    fr.client_name, 
    fr.total_loss, 
    fr.total_sale,
    fr.total_failed_transactions,
    fr.total_completed_transactions,
    (fr.total_failed_transactions + fr.total_completed_transactions) AS total_transactions
FROM final_result fr
ORDER BY fr.order_date DESC, fr.city_name;





/*
SELECT distinct order_guid,x.* FROM public.orders x
WHERE date(created_at)='2024-05-03' and  registration_id ='15261c8f-4339-4a6e-917d-3442c44bb5c5'

*order_guid in('51baa5df-22e7-4f3d-9e0e-7fcef916cec3'
,'ce368cee-5424-4466-eecd-c01b280b161a')
**/