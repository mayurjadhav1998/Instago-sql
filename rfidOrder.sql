WITH tbl1 AS (
    SELECT id as wallet_id, rfid as rfid_internal_number, rfid_amount as current_rfid_balance
    from wallets w
    where
    w.client_id = '305' 
    AND w.rfid IS NOT NULL
),
--select * from tbl1
 
tbl2 as(
   select service_request_id,parameter_details,wt.id,tbl1.wallet_id,rfid_internal_number,current_rfid_balance,registration_id,order_guid,
  -- cast(regexp_replace(split_part(parameter_details, 'amount:', 2), '[^0-9\.]', '', 'g') as numeric) as order_txn_amount,
           CAST(CAST(REGEXP_REPLACE(SPLIT_PART(parameter_details, 'amount:', 2), '[^0-9\.]', '', 'g') AS numeric) / 10 AS INTEGER) AS order_txn_amount,

   cast(regexp_replace(split_part(response, ':rfid_amount:', 2), '[^0-9\.]', '', 'g') as numeric) as rfid_balance_after_txn
   FROM wallet_transactions wt 
   join tbl1 on wt.wallet_id = tbl1.wallet_id
   join service_requests sr on wt.service_request_id = sr.id
   where 
   wt.created_at >= '2024-08-08 00:00:00.000' 
   and wt.created_at <= '2024-08-08 23:59:59.000'
   and wt.transaction_type = 'DEDUCT_FROM_RFID'
   --and wt.amount_added >=0
)  

SELECT *
FROM tbl2