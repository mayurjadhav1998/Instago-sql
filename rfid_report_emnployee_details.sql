WITH rfid_report AS (
    SELECT 
        cities.name::VARCHAR AS branch,
        clients.name::VARCHAR AS client_name,        
        machines.machine_number as machine_name,
        wallets.id AS wallet_id,
        wallets.employee_code::text as employee_code,
        DATE(orders.created_at) AS order_date,
        p.name as product_name,
        p.price * op.product_quantity as amount,
        op.product_quantity as quantity,
        op.motor_number,
        orders.dispensing,
        sr.request_status
        
    FROM wallets
    JOIN machines ON wallets.client_id = machines.client_id
    JOIN wallet_transactions wt ON wallets.id = wt.wallet_id
    JOIN orders ON wt.order_id = orders.id
    JOIN orders_products op ON orders.id = op.order_id
    JOIN products p ON op.product_id = p.id
    JOIN service_requests sr ON wt.service_request_id = sr.id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE wt.amount_added > 0
    and  date(orders.created_at)='2024-09-05'
--    AND DATE(orders.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
--    AND DATE(orders.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
    AND wallets.employee_code = CAST($employee_code AS text) -- Cast the variable to text
    
    GROUP BY machines.machine_number, wallets.id,p.name,p.price,op.product_quantity,op.motor_number,orders.dispensing,sr.request_status, cities.name, DATE(orders.created_at), clients.name, wallets.name
    ORDER BY order_date DESC, branch
)
SELECT * 
FROM rfid_report;
