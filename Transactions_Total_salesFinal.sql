WITH completed_orders AS (
    SELECT DISTINCT order_guid
    FROM orders
    JOIN machines ON orders.registration_id = machines.registration_id
   -- join
    WHERE dispensing = 'completed'
    AND machines.client_id = $client_id
    --and machines.id =$machine_id--in(363
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
--)    
--$machine_id
	--and DATE(orders.created_at) >='2024-08-01'     AND DATE(orders.created_at) <='2024-08-31'
    --and DATE(orders.created_at) >='2024-05-01'     AND DATE(orders.created_at) <='2024-05-31'
    --and DATE(orders.created_at) >='2024-06-01'     AND DATE(orders.created_at) <='2024-06-30'
    --and DATE(orders.created_at) >='2024-07-01'     AND DATE(orders.created_at) <='2024-07-31'
    --and DATE(orders.created_at) >='2024-08-01'     AND DATE(orders.created_at) <='2024-08-20'
    
    
    AND DATE(orders.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')  --uncomment for custom input start_date
    AND DATE(orders.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')    --uncomment for custom input end_date
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
    WHERE orders.dispensing IS NOT null
    --and DATE(orders.created_at) >='2024-04-01'     AND DATE(orders.created_at) <='2024-04-30'
    --and DATE(orders.created_at) >='2024-05-01'     AND DATE(orders.created_at) <='2024-05-31'
    --and DATE(orders.created_at) >='2024-06-01'     AND DATE(orders.created_at) <='2024-06-30'
    --and DATE(orders.created_at) >='2024-07-01'     AND DATE(orders.created_at) <='2024-07-31'
    --and DATE(orders.created_at) >='2024-08-01'     AND DATE(orders.created_at) <='2024-08-31'
    --and DATE(orders.created_at) >='2024-04-01'     AND DATE(orders.created_at) <='2024-07-31'

    
    AND DATE(orders.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD') --uncomment for custom input start_date
    AND DATE(orders.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')   --uncomment for custom input end_date
    GROUP BY orders.order_guid
),
sales_data AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
        DATE(orders.created_at)::TEXT AS order_date,
        clients.name::VARCHAR AS client_name,
        machines.machine_number as machine_name,
        SUM(CASE 
            WHEN os.max_dispensing_status != 'completed' AND os.order_guid NOT IN (SELECT order_guid FROM completed_orders) THEN os.total_payment ELSE 0 END
        ) AS total_loss,
        COUNT(CASE 
            WHEN os.max_dispensing_status != 'completed' AND os.order_guid NOT IN (SELECT order_guid FROM completed_orders) THEN 1 ELSE NULL END
        ) AS total_failed_transactions,
        SUM(CASE 
            WHEN orders.dispensing = 'completed' THEN opt.payment_amount ELSE 0 END
        ) AS total_sale,
        COUNT(CASE 
            WHEN orders.dispensing = 'completed' THEN 1 ELSE NULL END
        ) AS total_completed_transactions
    FROM orders
    join order_payment_types opt on orders.id=opt.order_id
    JOIN order_status os ON orders.order_guid = os.order_guid
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE --cities.id =$city_id and
       clients.id = $client_id --uncomment for custom input client_id
      --and clients.id=317
      -- machines.id =$machine_id --comment to get clientwise_date and uncomment to get machine id wise data
    GROUP BY cities.name, DATE(orders.created_at), clients.name,machines.machine_number 
),
monthly_totals AS (
    SELECT
        'Total' AS city_name,
        UPPER(TO_CHAR(DATE_TRUNC('month', DATE(sd.order_date)), 'YYYY-Mon')) AS order_date,
        sd.client_name,
        sd.machine_name,
        SUM(sd.total_loss) AS total_loss,
        SUM(sd.total_failed_transactions) AS total_failed_transactions,
        SUM(sd.total_sale) AS total_sale,
        SUM(sd.total_completed_transactions) AS total_completed_transactions,
        SUM(sd.total_failed_transactions) + SUM(sd.total_completed_transactions) AS total_transactions
    FROM sales_data sd
    GROUP BY UPPER(TO_CHAR(DATE_TRUNC('month', DATE(sd.order_date)), 'YYYY-Mon')), sd.client_name,sd.machine_name
),
final_result AS (
    SELECT 
        sd.city_name, 
        sd.order_date, 
        sd.client_name,
        sd.machine_name,
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
        mt.machine_name,
        mt.total_loss, 
        mt.total_sale,
        mt.total_failed_transactions,
        mt.total_completed_transactions
    FROM monthly_totals mt
)
SELECT 
    fr.city_name, 
    fr.order_date, 
    fr.client_name,
    fr.machine_name,
    fr.total_loss, 
    fr.total_sale,
    fr.total_failed_transactions,
    fr.total_completed_transactions,
    (fr.total_failed_transactions + fr.total_completed_transactions) AS total_transactions
FROM final_result fr 
where city_name='Total'
ORDER BY fr.order_date DESC, fr.city_name;
