with tbl1 as(SELECT 
    machines.machine_number AS Machine_Number,
    cities.name AS City_Name,
    DATE(orders.created_at) AS Order_Date,
    orders.created_at as create_date,
    machines.id as machine_id,
    products.name as product_name, 
    orders_products.motor_number,
    orders_products.product_quantity ,
    SUM(order_payment_types.payment_amount) AS Total_Sales
FROM machines
JOIN orders ON machines.registration_id = orders.registration_id 
JOIN order_payment_types ON orders.id = order_payment_types.order_id
join orders_products on orders.id=orders_products.order_id
join products on orders_products.product_id = products.id
JOIN cities ON machines.city_id = cities.id
WHERE orders.dispensing = 'completed' 
--and cities.name='Mumbai'
and machines.client_id =$client_id
--and machines.registration_id =$reg_id
--and machines.id=$machine_id
--and motor_number=$motor_number
--and orders.created_at >='2024-08-20 11:54:55.190'
--and orders.created_at <='2024-08-20 12:49:45.314'

AND DATE(order_payment_types.created_at) >= TO_DATE(CAST($Start_date AS TEXT), 'YYYY-MM-DD') AND DATE(order_payment_types.created_at) <= TO_DATE(CAST($end_date AS TEXT), 'YYYY-MM-DD')
GROUP BY machines.id, machines.machine_number,products.name,orders_products.product_quantity,orders_products.motor_number, cities.name,orders.created_at
)
select * from tbl1
union all 
 SELECT 
    Machine_Number,
     'total' City_Name,
    Order_Date,
    date(create_date) as order_time,
    machine_id,
    product_name, 
    motor_number,
    sum(product_quantity) as product_quantity ,
    SUM(total_sales) AS Total_Sales
from tbl1
group by tbl1.machine_number,tbl1.order_date,tbl1.create_date,tbl1.machine_id,tbl1.product_name,tbl1.motor_number

order by city_name