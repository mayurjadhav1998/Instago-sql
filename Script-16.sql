WITH completed_orders AS (
    SELECT DISTINCT order_guid
    FROM orders
    JOIN machines ON orders.registration_id = machines.registration_id
    WHERE dispensing = 'completed'
    AND machines.client_id = 243
    AND DATE(orders.created_at) >= '2024-06-01'
    AND DATE(orders.created_at) <= '2024-06-30'
),
order_status AS (
    SELECT 
        orders.order_guid,
        sum(product_quantity * mrp) AS purchase_amount,
        MAX(orders.dispensing) AS max_dispensing_status,
        MAX(order_payment_types.payment_amount) AS total_payment
    FROM orders
    JOIN order_payment_types ON orders.id = order_payment_types.order_id
    JOIN orders_products op ON orders.id = op.order_id
    JOIN products p ON op.product_id = p.id
    WHERE orders.dispensing IS NOT NULL
    AND DATE(orders.created_at) >= '2024-06-01'
    AND DATE(orders.created_at) <= '2024-06-30'
    GROUP BY orders.order_guid
),
unique_order_status AS (
    SELECT 
        order_guid,
        SUM(purchase_amount) AS purchased_amount,
        MAX(max_dispensing_status) AS max_dispensing_status,
        MAX(total_payment) AS total_payment
    FROM order_status
    GROUP BY order_guid
)
--SELECT * FROM unique_order_status
,
sales_data AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
        DATE(orders.created_at)::TEXT AS order_date,
        clients.name::VARCHAR AS client_name,
        SUM(CASE 
            WHEN uos.max_dispensing_status = 'started' AND uos.order_guid NOT IN (select distinct order_guid FROM completed_orders) THEN uos.total_payment ELSE 0 END
        ) AS total_possible_loss,
        SUM(CASE 
            WHEN uos.max_dispensing_status != 'completed' AND uos.order_guid NOT IN (select distinct order_guid FROM completed_orders) THEN uos.purchased_amount ELSE 0 END
        ) AS total_purchase_loss,
        --SUM(CASE 
          --  WHEN uos.max_dispensing_status != 'completed' THEN uos.purchased_amount ELSE 0 END
        --) AS total_purchase_loss,
        COUNT(CASE 
            WHEN uos.max_dispensing_status != 'completed' AND uos.order_guid NOT IN (SELECT order_guid FROM completed_orders) THEN 1 ELSE NULL END
        ) AS total_failed_transactions,
        /*COUNT(CASE 
            WHEN uos.max_dispensing_status != 'completed' AND uos.order_guid NOT IN (SELECT order_guid FROM completed_orders) THEN 1 ELSE NULL END
        ) AS purchase_failed_transactions,*/
        SUM(CASE 
            WHEN uos.max_dispensing_status = 'completed' THEN uos.total_payment ELSE 0 END
        ) AS total_sale,
        COUNT(CASE 
            WHEN uos.max_dispensing_status = 'completed' THEN 1 ELSE NULL END
        ) AS total_completed_transactions
    FROM orders
    JOIN unique_order_status uos ON orders.order_guid = uos.order_guid
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE cities.id = 11 -- $city_id
      AND clients.id = 243 -- $client_id -- Uncomment for custom input client_id
    GROUP BY cities.name, DATE(orders.created_at), clients.name  --, orders.id
)
--select * from sales_data
,
monthly_totals AS (
    SELECT
        'Total' AS city_name,
        UPPER(TO_CHAR(DATE_TRUNC('month', DATE(sd.order_date)), 'YYYY-Mon')) AS order_date,
        sd.client_name,
        SUM(sd.total_possible_loss) AS total_possible_loss,
        SUM(sd.total_purchase_loss) AS total_purchase_loss,
        
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
        sd.total_possible_loss,
        sd.total_purchase_loss,
        sd.total_sale,
        sd.total_failed_transactions,
        sd.total_completed_transactions
    FROM sales_data sd
    UNION ALL
    SELECT 
        mt.city_name, 
        mt.order_date, 
        mt.client_name, 
        mt.total_possible_loss,
        mt.total_purchase_loss,
        mt.total_sale,
        mt.total_failed_transactions,
        mt.total_completed_transactions
    FROM monthly_totals mt
)
select * from sales_data

SELECT 
    fr.city_name, 
    fr.order_date, 
    fr.client_name, 
    fr.total_possible_loss, 
    fr.total_purchase_loss,
    fr.total_sale,
    fr.total_failed_transactions,
    fr.total_completed_transactions,
    (fr.total_failed_transactions + fr.total_completed_transactions) AS total_transactions
FROM final_result fr
ORDER BY fr.order_date DESC, fr.city_name;












------------------------------------------------------------------------------------------
--
--WITH completed_orders AS (
--    SELECT DISTINCT order_guid
--    FROM orders
--    JOIN machines ON orders.registration_id = machines.registration_id
--    WHERE dispensing = 'completed'
--    AND machines.client_id = 243
--    AND DATE(orders.created_at) >= '2024-06-01'
--    AND DATE(orders.created_at) <= '2024-06-30'
--),
--started_but_not_completed AS (
--    SELECT DISTINCT order_guid
--    FROM orders
--    WHERE dispensing = 'started'
--    AND order_guid NOT IN (
--        SELECT order_guid
--        FROM completed_orders
--    )
--),
--order_status AS (
--    SELECT 
--        orders.order_guid,
--        SUM(op.product_quantity * p.mrp) AS purchase_amount,
--        MAX(orders.dispensing) AS max_dispensing_status,
--        MAX(opt.payment_amount) AS total_payment
--    FROM orders
--    JOIN order_payment_types opt ON orders.id = opt.order_id
--    JOIN orders_products op ON orders.id = op.order_id
--    JOIN products p ON op.product_id = p.id
--    WHERE orders.dispensing IS NOT NULL
--    AND DATE(orders.created_at) >= '2024-06-01'
--    AND DATE(orders.created_at) <= '2024-06-30'
--    AND orders.order_guid IN (
--        SELECT order_guid FROM started_but_not_completed
--    )
--    GROUP BY orders.order_guid
--),
--unique_order_status AS (
--    SELECT 
--        order_guid,
--        SUM(purchase_amount) AS purchased_amount,
--        MAX(max_dispensing_status) AS max_dispensing_status,
--        MAX(total_payment) AS total_payment
--    FROM order_status
--    GROUP BY order_guid
--),
--sales_data AS (
--    SELECT 
--        'YourCityName' AS city_name,  -- Replace with actual city logic if available
--        orders.created_at AS order_date, 
--        machines.client_id AS client_name,  -- Adjust this if `client_name` is not `client_id`
--        SUM(op.product_quantity * p.mrp) AS total_possible_loss,
--        SUM(CASE 
--                WHEN orders.dispensing = 'failed' THEN op.product_quantity * p.mrp 
--                ELSE 0 
--            END) AS total_purchase_loss,
--        SUM(CASE 
--                WHEN orders.dispensing = 'completed' THEN op.product_quantity * p.mrp 
--                ELSE 0 
--            END) AS total_sale,
--        SUM(CASE 
--                WHEN orders.dispensing != 'completed' THEN 1 
--                ELSE 0 
--            END) AS total_failed_transactions,
--        SUM(CASE 
--                WHEN orders.dispensing = 'completed' THEN 1 
--                ELSE 0 
--            END) AS total_completed_transactions
--    FROM orders
--    JOIN machines ON orders.registration_id = machines.registration_id
--    JOIN orders_products op ON orders.id = op.order_id
--    JOIN products p ON op.product_id = p.id
--    WHERE DATE(orders.created_at) >= '2024-06-01'
--    AND DATE(orders.created_at) <= '2024-06-30'
--    GROUP BY orders.created_at, machines.client_id
--),
--monthly_totals AS (
--    SELECT
--        'Total' AS city_name,
--        UPPER(TO_CHAR(DATE_TRUNC('month', DATE(sd.order_date)), 'YYYY-Mon')) AS order_date,
--        sd.client_name,
--        SUM(sd.total_possible_loss) AS total_possible_loss,
--        SUM(sd.total_purchase_loss) AS total_purchase_loss,
--        SUM(sd.total_sale) AS total_sale,
--        SUM(sd.total_failed_transactions) AS total_failed_transactions,
--        SUM(sd.total_completed_transactions) AS total_completed_transactions,
--        SUM(sd.total_failed_transactions) + SUM(sd.total_completed_transactions) AS total_transactions
--    FROM sales_data sd
--    GROUP BY UPPER(TO_CHAR(DATE_TRUNC('month', DATE(sd.order_date)), 'YYYY-Mon')), sd.client_name
--),
--final_result AS (
--    SELECT 
--        sd.city_name, 
--        sd.order_date, 
--        sd.client_name, 
--        sd.total_possible_loss,
--        sd.total_purchase_loss,
--        sd.total_sale,
--        sd.total_failed_transactions,
--        sd.total_completed_transactions
--    FROM sales_data sd
--    UNION ALL
--    SELECT 
--        mt.city_name, 
--        mt.order_date, 
--        mt.client_name, 
--        mt.total_possible_loss,
--        mt.total_purchase_loss,
--        mt.total_sale,
--        mt.total_failed_transactions,
--        mt.total_completed_transactions
--    FROM monthly_totals mt
--)
--SELECT 
--    fr.city_name, 
--    fr.order_date, 
--    fr.client_name, 
--    fr.total_possible_loss, 
--    fr.total_purchase_loss,
--    fr.total_sale,
--    fr.total_failed_transactions,
--    fr.total_completed_transactions,
--    (fr.total_failed_transactions + fr.total_completed_transactions) AS total_transactions
--FROM final_result fr
--ORDER BY fr.order_date DESC, fr.city_name;























/*
SELECT distinct order_guid,x.* FROM public.orders x
WHERE date(created_at)='2024-05-03' and  registration_id ='15261c8f-4339-4a6e-917d-3442c44bb5c5'

*
**/



/*WITH completed_orders AS (
    SELECT *,orders.created_at as order_date,orders.id  as order_id
    FROM orders
    JOIN machines ON orders.registration_id = machines.registration_id
    WHERE dispensing = 'started'
    AND machines.client_id = 243
    AND DATE(orders.created_at) >= '2024-05-01'
    AND DATE(orders.created_at) <= '2024-08-31'
    
    
)
select * from completed_orders  ---started	625
,
/*order_status AS (
    SELECT 
        orders.order_guid,
        MAX(orders.dispensing) AS max_dispensing_status,
        SUM(order_payment_types.payment_amount) AS total_payment
    FROM orders
    JOIN order_payment_types ON orders.id = order_payment_types.order_id
    WHERE orders.dispensing IS NOT NULL
    AND DATE(orders.created_at) >= '2024-05-01'
    AND DATE(orders.created_at) <= '2024-08-31'
    GROUP BY orders.order_guid
),*/
tbl3 AS(
SELECT dispensing, COUNT(*) AS count
from completed_orders
--FROM order_status
GROUP BY  dispensing
having count(*) > 1
ORDER BY count DESC
)
select * from tbl3
*/