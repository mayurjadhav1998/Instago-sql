with distinct_order as(
select distinct order_guid,*
from orders
where orders.dispensing ='completed'
--and orders.order_guid not in 

),

with consecutive_started as( 
SELECT o.*,opt.payment_amount FROM orders o
JOIN order_payment_types opt ON o.id = opt.order_id
WHERE registration_id ='15261c8f-4339-4a6e-917d-3442c44bb5c5'
and date(o.created_at )>= '2024-06-01' and date(o.created_at )<='2024-06-30' --and dispensing='started'

ORDER BY o.created_at
)
select * from consecutive_started
, 


 completed_orders AS (
    SELECT DISTINCT order_guid as order_guid1, orders.*
    FROM orders
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE 
  	DATE(orders.created_at) >= '2024-06-01'
    AND DATE(orders.created_at) <= '2024-06-30'
    and cities.id = $city_id
    AND clients.id = $client_id 
    and dispensing = 'completed'
-- Uncomment for custom input client_id
    GROUP BY cities.name, DATE(orders.created_at), clients.name , order_guid1, orders.id
),
started_orders AS (
    SELECT DISTINCT order_guid as order_guid1, orders.*
    FROM orders
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE 
  	DATE(orders.created_at) >= '2024-06-01'
    AND DATE(orders.created_at) <= '2024-06-30'
    and cities.id = $city_id
    AND clients.id = $client_id 
    and dispensing = 'started'
    AND order_guid NOT IN (
        SELECT order_guid
        FROM completed_orders
    )
-- Uncomment for custom input client_id
    GROUP BY cities.name, DATE(orders.created_at), clients.name , order_guid1, orders.id
)
--select * from completed_orders
,

order_details_started AS (
    SELECT 
        order_guid1,
        sum(product_quantity * mrp) AS purchase_amount,
        order_payment_types.payment_amount AS total_payment
    FROM started_orders
    JOIN order_payment_types ON started_orders.id = order_payment_types.order_id
    JOIN orders_products op ON started_orders.id = op.order_id
    JOIN products p ON op.product_id = p.id
    WHERE dispensing IS NOT NULL
    AND DATE(started_orders.created_at) >= '2024-06-01'
    AND DATE(started_orders.created_at) <= '2024-06-30'
    group by order_guid1, payment_amount
),

order_details_completed AS (
    SELECT 
        order_guid1,
        sum(product_quantity * mrp) AS purchase_amount,
        order_payment_types.payment_amount AS total_payment
    FROM completed_orders
    JOIN order_payment_types ON completed_orders.id = order_payment_types.order_id
    JOIN orders_products op ON completed_orders.id = op.order_id
    JOIN products p ON op.product_id = p.id 
    WHERE dispensing IS NOT NULL
    AND DATE(completed_orders.created_at) >= '2024-06-01'
    AND DATE(completed_orders.created_at) <= '2024-06-30'
    group by order_guid1, payment_amount
),
started_sales_data AS (
    SELECT 
		count(order_details_started.order_guid1) as total_started_transactions,
        SUM(order_details_started.total_payment) as total_possible_loss
        from order_details_started
        ),

        

completed_sales_data AS (
    SELECT 
        count(order_details_completed.order_guid1) as total_completed_transactions, 
        SUM(order_details_completed.total_payment) as total_sale
        from order_details_completed
        ),
        

sales_data AS (
    SELECT 
        (total_completed_transactions+total_started_transactions) as total_transactions,
       	total_completed_transactions, 
        total_started_transactions, 
		(total_sale+total_possible_loss)as total_order_value,
        total_sale,
        total_possible_loss,
        (total_possible_loss/(total_sale+total_possible_loss)*100) as total_loss_percentage
        from order_details_completed
        )
        
select * from sales_data
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





/*
SELECT distinct order_guid,x.* FROM public.orders x
WHERE date(created_at)='2024-05-03' and  registration_id ='15261c8f-4339-4a6e-917d-3442c44bb5c5'

*order_guid in('51baa5df-22e7-4f3d-9e0e-7fcef916cec3'
,'ce368cee-5424-4466-eecd-c01b280b161a')
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