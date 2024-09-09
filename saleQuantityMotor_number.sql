WITH tbl1 AS (
    SELECT 
        machines.machine_number AS Machine_Number,
        cities.name AS City_Name,
        DATE(orders.created_at) AS Order_Date,
        orders.created_at AS create_date,
        machines.id AS machine_id,
        products.name AS product_name, 
        orders_products.motor_number,
        orders_products.product_quantity,
        order_payment_types.payment_amount AS Total_Sales
    FROM machines
    JOIN orders ON machines.registration_id = orders.registration_id 
    JOIN order_payment_types ON orders.id = order_payment_types.order_id
    JOIN orders_products ON orders.id = orders_products.order_id
    JOIN products ON orders_products.product_id = products.id
    JOIN cities ON machines.city_id = cities.id
    WHERE --orders.dispensing = 'completed' AND 
    motor_number = $motor_number
    -- AND cities.name = 'Mumbai'
    -- AND machines.registration_id = $reg_id
    AND machines.id = $machine_id
    AND orders.created_at >= '2024-08-13 11:54:55.190'
    AND orders.created_at <= '2024-08-14 12:49:45.314'
)
SELECT * FROM tbl1;
--union all
