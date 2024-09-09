WITH tbl1 AS (
    SELECT 
        id AS wallet_id, 
        rfid AS rfid_internal_number, 
        rfid_amount AS current_rfid_balance, 
        monthly_limit
    FROM wallets w
    WHERE w.client_id = 214
      AND w.rfid IS NOT NULL
),

tbl2 AS (
    SELECT 
        service_request_id,
        registration_id,
        order_guid,
        monthly_limit,
        wt.id,
        tbl1.wallet_id,
        rfid_internal_number,
        tbl1.current_rfid_balance,
        CAST(CAST(REGEXP_REPLACE(SPLIT_PART(parameter_details, 'amount:', 2), '[^0-9\.]', '', 'g') AS numeric) / 10 AS INTEGER) AS order_txn_amount,
        CAST(REGEXP_REPLACE(SPLIT_PART(response, ':rfid_amount:', 2), '[^0-9\.]', '', 'g') AS numeric) AS rfid_balance_after_txn
    FROM wallet_transactions wt
    JOIN tbl1 ON wt.wallet_id = tbl1.wallet_id
    JOIN service_requests sr ON wt.service_request_id = sr.id
    WHERE wt.created_at BETWEEN '2024-07-01 00:00:00.000' AND '2024-07-13 23:59:59.000'
      AND wt.transaction_type = 'DEDUCT_FROM_RFID'
      AND sr.response IS NOT NULL
      AND wt.amount_added > 0
),

tbl3 AS (
    SELECT 
        order_guid, 
        COUNT(*) AS count
    FROM tbl2
    GROUP BY order_guid
    HAVING COUNT(*) > 1
),

tbl4 AS (
    SELECT 
        tbl2.registration_id,
        tbl2.order_guid, 
        tbl2.count, 
        tbl2.order_txn_amount, 
        SUM(tbl2.order_txn_amount) AS total_deduction, 
        SUM(tbl2.order_txn_amount) - tbl2.order_txn_amount AS amount_to_refund, 
        tbl2.wallet_id, 
        tbl2.rfid_internal_number, 
        tbl2.monthly_limit, 
        tbl2.current_rfid_balance
    FROM tbl2
    JOIN tbl3 ON tbl2.order_guid = tbl3.order_guid
    GROUP BY 
        tbl2.order_guid, 
        tbl2.order_txn_amount, 
        tbl2.registration_id, 
        tbl2.wallet_id, 
        tbl2.rfid_internal_number, 
        tbl2.monthly_limit, 
        tbl2.current_rfid_balance
)

SELECT 
    tbl4.registration_id, 
    tbl4.wallet_id, 
    tbl4.rfid_internal_number, 
    tbl4.monthly_limit, 
    tbl4.current_rfid_balance, 
    SUM(tbl4.order_txn_amount) AS total_order_txn_amount, 
    SUM(tbl4.total_deduction) AS total_sum_deduction, 
    SUM(tbl4.amount_to_refund) AS total_amount_to_refund
FROM tbl4
GROUP BY 
    tbl4.rfid_internal_number, 
    tbl4.wallet_id, 
    tbl4.monthly_limit, 
    tbl4.current_rfid_balance, 
    tbl4.registration_id;


