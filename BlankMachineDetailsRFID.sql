WITH blank_name AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
       DATE(orders.created_at) AS order_date,
        clients.name::VARCHAR AS client_name,
        machines.machine_number as machine_name,
        machines.machine_serial_number,
		orders.order_guid,
		opt.payment_mode
		,orders.rfid,
		w.name,
		w.instago_card_number as order_instago_card_number
		

    FROM orders
    join order_payment_types opt on orders.id =opt.order_id
    join wallets w on orders.rfid =w.rfid
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE  --DATE(orders.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
      --AND DATE(orders.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD') and
       orders.order_guid in(
       
'e7a52899-631b-4330-d32f-3a2c028121f4',
'881907ec-7d73-4964-d02d-5a70b80448d8',
'2a96d044-c0fc-4f16-df88-f4c33039cd61',
'f423d707-2b87-4b4a-db94-52898a671200',
'1606bffb-be0c-4a59-b8ef-bd18392a2920',
'0d7cc9be-1b0c-4c30-703c-23eb6a96efad',
'275c5d62-90e4-4e2c-2096-a945929f770e',
'e8997b42-c76f-41ae-3db2-090ca8db297e',
'ac7949ea-8ea7-43f7-b21f-6ae164fd9c63',
'6128f3eb-5f10-44b0-082c-e175f6884600',
'6128f3eb-5f10-44b0-082c-e175f6884600',
'b0c0cd9c-831c-48ec-8480-3da35aabc9b4',
'b0c0cd9c-831c-48ec-8480-3da35aabc9b4',
'06895e4c-2171-4beb-66de-91f4daff0529',
'187bf86b-fecd-40c9-54d1-740784a08f85',
'e3b34b85-081a-4e9c-0a55-5ee0e384ca96',
'ebcebec0-d0ac-4cbe-3f40-b452899d79b7',
'a29d2194-7a97-4d72-6076-4af427b55867',
'befd2f08-5b2e-423c-cca5-a8927f8adeae',
'befd2f08-5b2e-423c-cca5-a8927f8adeae',
'befd2f08-5b2e-423c-cca5-a8927f8adeae',
'1aded31e-0efc-4007-b380-da45eb159237',
'da0fac74-dd6d-4f25-e557-97e80e684116'

       )

      
      
      
    GROUP BY orders.order_guid,
    	orders.rfid,
    	orders.created_at,
		w.name,
		w.instago_card_number,
		machines.machine_number,
		machines.machine_serial_number,
		opt.payment_mode,
		cities.name,
		DATE(orders.created_at),
		clients.name
)
SELECT * FROM blank_name
