WITH tbl1 AS (
    SELECT *,
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
    WHERE sr.action = 'add_and_deduct_amount_in_rfid'
      AND sr.created_at >= '2024-07-01 00:00:00.000'
      AND sr.created_at <= '2024-07-29 23:59:59.000'
      AND sr.parameter_details IS NOT NULL
),
tbl2 AS (
    select tbl1.registration_id, tbl1.rfid, tbl1.id, tbl1.created_at, tbl1.updated_at,  tbl1.order_guid, tbl1.order_txn_amount, tbl1.rfid_balance_after_txn
    FROM tbl1
    WHERE tbl1.order_txn_amount > 0
      AND tbl1.rfid = '1B004BAE9769'
),
tbl3 AS (
    SELECT tbl2.*, o.dispensing, o.balance_amount as ord_balance_amount, 
           w.id AS wallets_id, 
           w.rfid_amount as current_rfid_balance, w.monthly_limit, w.instago_card_number
    FROM tbl2
    LEFT JOIN orders o ON tbl2.order_guid = o.order_guid
    JOIN wallets w ON tbl2.rfid = w.rfid
)
--SELECT * FROM tbl3;
SELECT registration_id, wallets_id, rfid, instago_card_number, monthly_limit,order_txn_amount, 
	(rfid_balance_after_txn + order_txn_amount) as rfid_balance_before_txn ,
	rfid_balance_after_txn,ord_balance_amount, dispensing, order_guid, 
    current_rfid_balance, created_at, updated_at,id as service_req_id
FROM tbl3
order by created_at desc;
