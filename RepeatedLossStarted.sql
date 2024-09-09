WITH consecutive_started AS (
    SELECT
        o.id,
        o.created_at,
        o.updated_at,
        o.registration_id,
        o.order_time_stamp,
        o.order_guid,
        o.dispensing,
        opt.payment_amount,
        ROW_NUMBER() OVER (ORDER BY o.created_at) AS rn,
        LAG(o.dispensing) OVER (ORDER BY o.created_at) AS prev_dispensing
    FROM orders o
    --join machines on o.registration_id=o.registration_id
    JOIN order_payment_types opt ON o.id = opt.order_id
    WHERE --machines.id=633 --$machine_id--
    --o.registration_id = 'f46512b8-ad45-4a36-a918-e88fc74cead0'
      --AND DATE(o.created_at) >=$start_date --'2024-06-07'
      --AND DATE(o.created_at) <=$end_date --'2024-06-7'
    --and DATE(o.created_at) >='2024-04-01'     AND DATE(o.created_at) <='2024-04-30'
    --and DATE(o.created_at) >='2024-05-01'     AND DATE(o.created_at) <='2024-05-31'
    --and DATE(o.created_at) >='2024-06-01'     AND DATE(o.created_at) <='2024-06-30'
     DATE(o.created_at) >='2024-08-01'     AND DATE(o.created_at) <='2024-08-24'
    --and DATE(o.created_at) >=$start_date     AND DATE(o.created_at) <=$start_date
    and o.registration_id in(

--'ba8e7b02-7603-44cc-93d4-5f646b5c68d3'
--'aafaa1b7-981a-4f73-b52f-3ae6b5482605'
'47b82dda-7bfa-4b75-8a22-b3d73e67adf1'    
    )
),
consecutive_counts AS (
    SELECT
        *,
        CASE
            WHEN dispensing = 'started' AND prev_dispensing = 'started' THEN 1
            ELSE 0
        END AS is_started_consecutive
    FROM consecutive_started
),
grouped_counts AS (
    SELECT
        *,
        SUM(is_started_consecutive) OVER (PARTITION BY payment_amount ORDER BY rn ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS started_count
    FROM consecutive_counts
),
filtered_counts AS (
    SELECT
        *,
        CASE
            WHEN dispensing = 'started' AND (LAG(dispensing) OVER (PARTITION BY payment_amount ORDER BY rn) = 'started') THEN started_count
            ELSE 0
        END AS counted_started
    FROM grouped_counts
),
repeated_loss AS (
    SELECT
        *,
        MAX(counted_started) OVER (PARTITION BY payment_amount ORDER BY rn ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS final_started_count
    FROM filtered_counts
),
final_counts AS (
    SELECT
        DISTINCT
        dispensing,
        --prev_dispensing,
        payment_amount,
        final_started_count AS repeated_started_count,
        
        --max(final_started_count) AS repeated_started_count,
        (final_started_count * payment_amount) AS repeated_loss_amount,
        created_at  -- Make sure to include created_at here
    FROM repeated_loss
    WHERE dispensing = 'started' OR final_started_count > 1
    --and repeated_started_count!=0
--    group by repeated_loss.dispensing,
--        --prev_dispensing,
--        repeated_loss.payment_amount,
--       repeated_loss.final_started_count,
--        --final_started_count * payment_amount AS repeated_loss_amount,
--        repeated_loss.created_at
)
,
tbl1 as(
SELECT
    dispensing,
    --prev_dispensing,
    max(payment_amount) as payment_amount,
    --sum(payment_amount) as payment_amount,

    max(repeated_started_count)as repeated_started_count
    ,(repeated_loss_amount-payment_amount) as repeat_loss
    FROM final_counts
where repeated_started_count!=0 and dispensing !='completed'
group by final_counts.dispensing,--final_counts.prev_dispensing,
final_counts.payment_amount,final_counts.repeated_loss_amount,final_counts.created_at
ORDER BY created_at
)

,

RankedLosses AS (
    SELECT
        dispensing,
        payment_amount,
        repeated_started_count,
        repeat_loss,
        ROW_NUMBER() OVER (PARTITION BY payment_amount ORDER BY repeat_loss DESC) AS rn
    FROM
        tbl1
),
tbl2 as(SELECT
    dispensing,
    payment_amount,
    repeated_started_count,
    repeat_loss
FROM
    RankedLosses
WHERE
    rn = 1
),
tbl3 as (select * from tbl2
union all
select 
'total' as dispensing,
--0 as payment_amount,
sum(payment_amount) as payment_amount,
sum(repeated_started_count) as repeated_started_count,
    sum(repeat_loss) as repeat_loss
    from tbl2
    order by dispensing desc)
    
select * from tbl3 -- uncomment to see the consecutive_started loss


--select * from repeated_loss --uncomment to see consecutive_started count

















-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
--with tblz as(
--select product_guid,
--	products.name as product_name,product_quantity,
--	product_quantity * price as selling_price
--from orders_products
--join products on orders_products.product_id =products.id
--where
--order_id IN (
--    8668532, 8668847, 8670567, 8670645, 8670657, 8670670, 8670731, 8670931,
--    8671012, 8671167, 8671484, 8671611, 8671622, 8671681, 8671887, 8671997,
--    8672100, 8672132, 8672235, 8672314, 8672340, 8672386, 8672837, 8672850,
--    8672903, 8672988, 8673079, 8673140, 8673302, 8673966, 8674011, 8674048,
--    8674060, 8674085, 8674180, 8674357, 8674587, 8674732, 8674766, 8674856,
--    8675319, 8675959, 8676071, 8676394, 8676513, 8676819, 8677217, 8677550,
--    8677928, 8677965, 8678149, 8678189, 8678444, 8678506, 8678667, 8678755,
--    8679088
--)
--)
--select * from tblz
--group by tblz.product_guid,tblz.product_name,tblz.product_quantity,tblz.selling_price
--
--union all 
--select 
--'total'as  product_guid,
-- product_name,
--sum(product_quantity),
--sum(selling_price)
--from tblz
--group by tblz.product_guid,tblz.product_name,tblz.product_quantity,tblz.selling_price
--
--
--
--


























