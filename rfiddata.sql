WITH tbl1 AS (
    SELECT id AS wallet_id, rfid AS rfid_internal_number, rfid_amount AS current_rfid_balance, monthly_limit
    FROM wallets w
    WHERE w.instago_card_number = '000000006057' 
      AND w.rfid IS NOT NULL
),

tbl2 AS (
    SELECT 
        service_request_id,
        --parameter_details as text_parameter_details,
        --response,
        registration_id,
        order_guid,
        monthly_limit,
        wt.id,
        tbl1.wallet_id,
        rfid_internal_number,
        tbl1.current_rfid_balance,
        cast(cast(regexp_replace(split_part(parameter_details, 'amount:', 2), '[^0-9\.]', '', 'g') as numeric)/10 as integer) as order_txn_amount,
        CAST(REGEXP_REPLACE(SPLIT_PART(response, ':rfid_amount:', 2), '[^0-9\.]', '', 'g') AS numeric) AS rfid_balance_after_txn
    FROM wallet_transactions wt
    JOIN tbl1 ON wt.wallet_id = tbl1.wallet_id
    JOIN service_requests sr ON wt.service_request_id = sr.id
    WHERE wt.created_at >= '2024-07-26 00:00:00.000'
      AND wt.created_at <= '2024-07-29 23:59:59.000'
      AND wt.transaction_type = 'DEDUCT_FROM_RFID'
      and sr.response is not null
      AND wt.amount_added > 0
),

--SELECT *, (order_txn_amount + rfid_balance_after_txn) as rfid_balance_before_txn FROM tbl2;
tbl3 AS(
SELECT order_guid, COUNT(*) AS count
FROM tbl2
GROUP BY order_guid
having count(*) > 1
ORDER BY count DESC
)

--select * from tbl3

select tbl2.registration_id,tbl2.order_guid, tbl2.count, tbl2.order_txn_amount, sum(tbl2.order_txn_amount) as total_deduction, sum(tbl2.order_txn_amount)-tbl2.order_txn_amount as amount_to_refund, tbl2.wallet_id, tbl2.rfid_internal_number, tbl2.monthly_limit, tbl2.current_rfid_balance
FROM tbl2
JOIN tbl3 ON tbl2.order_guid = tbl3.order_guid
GROUP BY tbl2.order_guid, tbl2.order_txn_amount, tbl2.registration_id, tbl2.wallet_id, tbl2.rfid_internal_number, tbl2.monthly_limit, tbl2.current_rfid_balance