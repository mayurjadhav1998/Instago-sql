WITH blank_name AS (
    SELECT 
        cities.name::VARCHAR AS city_name,
       DATE(orders.created_at) AS order_date,
        --TO_CHAR(DATE(orders.created_at), 'YYYY-MM-DD') AS order_date,
        clients.name::VARCHAR AS client_name,
        machines.machine_number as machine_name,
        machines.machine_serial_number,
		orders.order_guid,
		opt.payment_mode
		--,orders.rfid,
		--w.name

    FROM orders
    join order_payment_types opt on orders.id =opt.order_id
    --join wallets w on orders.rfid =w.rfid
    JOIN machines ON orders.registration_id = machines.registration_id
    JOIN cities ON machines.city_id = cities.id
    JOIN clients ON machines.client_id = clients.id
    WHERE  --DATE(orders.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD')
      --AND DATE(orders.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD') and
       orders.order_guid in(
 

'7197cdec-6669-4c76-1ad1-49e89ad948db',
'7197cdec-6669-4c76-1ad1-49e89ad948db',
'bf280599-1ddf-4ff7-70b4-dc9b346f0e6b',
'bf280599-1ddf-4ff7-70b4-dc9b346f0e6b',
'14ac8747-c3c2-47a4-a65e-6a50a4003a9b',
'14ac8747-c3c2-47a4-a65e-6a50a4003a9b',
'39a34187-68e7-43eb-2874-09da18e0c7c8',
'6f0788f1-3ae4-4985-4340-e77549af690d',
'3c9f36d7-8692-48c8-b67e-a9301dfe4a49',
'f3daae8f-57c7-4a30-5304-1a37ba38d8c7',
'192ff0a5-4187-4bf9-7b8a-e6321c037037',
'8da5d32b-4113-4281-3283-90d20f46f029',
'67d1f154-a5ab-4e46-25b9-5a82c2d21a22',
'9b0082e1-79e7-46d4-cb34-9de0fd53c4c1',
'9b0082e1-79e7-46d4-cb34-9de0fd53c4c1',
'9cdaef07-6c32-4db2-cf8d-5dbeb853a0d6',
'7de0a983-5524-418c-dcbf-b9c68c13a48e',
'8dc89138-6477-461b-cfa2-81ac9db7008a',
'160ffdca-994a-41a9-540f-125cc3134f4e',
'160ffdca-994a-41a9-540f-125cc3134f4e',
'71fcecdc-690b-4981-5fe0-7c670ccf5f3e',
'71fcecdc-690b-4981-5fe0-7c670ccf5f3e',
'8823ace6-99c6-41ec-56e0-e53ba41eaf35',
'25e097be-709b-4b66-a1b5-6abad9b02f50',
'8a380669-7c31-4aa9-1de0-6ee7873793a7',
'8c2a64db-f86d-49f1-c974-6d1004b7c9b2'




       
       )

      
      
      
    GROUP BY orders.order_guid,
    	--orders.rfid,
    	orders.created_at,
		--w.name,
		machines.machine_number,
		machines.machine_serial_number,
		opt.payment_mode,
		cities.name,
		DATE(orders.created_at),
		clients.name
)
SELECT * FROM blank_name
