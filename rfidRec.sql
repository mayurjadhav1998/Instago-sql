

with tbl1 as(SELECT *,
       SUBSTRING(
           REGEXP_REPLACE(
               SPLIT_PART(sr.parameter_details, 'rfid_number:', 2), 
               '[^0-9A-F]', 
               '', 
               'g'
           ), 
           1, 
           12
       ) AS rfid,
        CAST(CAST(REGEXP_REPLACE(SPLIT_PART(sr.parameter_details, 'amount:', 2), '[^0-9\.]', '', 'g') AS float) / 10 AS integer) AS order_txn_amount,
        CAST(REGEXP_REPLACE(SPLIT_PART(sr.response, ':rfid_amount:', 2), '[^\d\.-]', '', 'g') AS float) AS rfid_balance_after_txn

FROM service_requests sr

WHERE sr.action ='add_and_deduct_amount_in_rfid'
and sr.created_at >= '2024-07-01 00:00:00.000'
and sr.created_at <= '2024-07-29 23:59:59.000'
and sr.parameter_details IS NOT null

--and order_guid is not null 
),
--and  is not null
--select *,tbl1.rfid from tbl1 where tbl1.rfid='04008BD6441D'

tbl2 as (
select tbl1.rfid,tbl1.id,tbl1.created_at,tbl1.updated_at,tbl1.registration_id, tbl1.order_guid,tbl1.rfid,tbl1.order_txn_amount,tbl1.rfid_balance_after_txn
 from tbl1
 where tbl1.order_txn_amount>0
 and tbl1.rfid='04008BD6441D'
 
)--,--cmt comma and run below select stmt
--/*
select *, (tbl2.rfid_balance_after_txn + tbl2.order_txn_amount) as rfid_balance_before_txn from tbl2
order by created_at desc 
--*/


tbl3 AS (
    SELECT tbl2.*, o.id, o.order_guid, o.dispensing, o.balance_amount, 
           w.id AS wallets_tbl_id, w.amount AS wallets_tbl_amount, 
           w.rfid_amount, w.monthly_limit, w.instago_card_number, 
           w.total_daily_limit, w.remaining_daily_limit
    FROM tbl2
    LEFT JOIN orders o ON tbl2.order_guid = o.order_guid
    JOIN wallets w ON tbl2.rfid = w.rfid
)
SELECT id, order_guid, dispensing, balance_amount, 
       wallets_tbl_id, wallets_tbl_amount, 
       rfid_amount, monthly_limit, 
       instago_card_number, total_daily_limit, 
       remaining_daily_limit
FROM tbl3;


