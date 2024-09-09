with tbl as (
    select order_guid, count(*)
    from service_requests_new sr
    where sr.created_at > '2024-07-01 00:00:01'
      and order_guid is not null
      and response is not null
      and "action" = 'add_and_deduct_amount_in_rfid'
    group by order_guid
    having count(*) > 1
    order by count(*) desc
),

tbl1 as (
    select id, order_guid, response, created_at,
           row_number() over (partition by order_guid order by created_at asc) as rn
    from service_requests_new sr
    where sr.created_at > '2024-07-11 00:00:01'
      and order_guid is not null
      and sr.order_guid in (select order_guid from tbl)
      and response is not null
      and "action" = 'add_and_deduct_amount_in_rfid'
),

tbl2 as (
    select t1.*, 
           t2.response as responsenext,
           cast(regexp_replace(split_part(t1.response, ':rfid_amount:', 2), '[^0-9\.]', '', 'g') as numeric) as rfid_amount,
           cast(regexp_replace(split_part(t2.response, ':rfid_amount:', 2), '[^0-9\.]', '', 'g') as numeric) as rfid_amount_next,
           --cast(regexp_replace(split_part(response, ':rfid_amount:', 2), '[^0-9\.]', '', 'g') as numeric)
           --cast(regexp_replace(split_part(parameter_details, ':amount:', 2), '[^0-9\.]', '', 'g') as numeric)
           
           substring(regexp_replace(split_part(t1.response, ':registration_id:', 2), '[^0-9a-f\-]', '', 'g'),1,36) as registration_id,
           substring(regexp_replace(split_part(t1.response, ':rfid_number:', 2), '[^0-9A-F]', '', 'g'), 1, 12) as rfid,
           substring(regexp_replace(split_part(t2.response, ':registration_id:', 2), '[^0-9a-f\-]', '', 'g'),1,36) as registration_id_next,
           substring(regexp_replace(split_part(t2.response, ':rfid_number:', 2), '[^0-9A-F]', '', 'g'), 1, 12) as rfid_next
    from tbl1 t1
    left join tbl1 t2
    on t1.order_guid = t2.order_guid and t1.rn = t2.rn - 1
),

final_query as (
    select *,
           (rfid_amount - rfid_amount_next) as sold_product_amount,
           (rfid_amount - rfid_amount_next) * rn as sold_product_amount_multiple_entries
    from tbl2
    where rfid_amount <> rfid_amount_next
      and responsenext is not null
      and registration_id = registration_id_next
      and rfid = rfid_next
)

select 
    f.*,
    o.balance_amount,
    o.id as orders_id,
    op.payment_amount,
    (sold_product_amount_multiple_entries - op.payment_amount) as loss_amount
from final_query f
join orders o
on f.registration_id = o.registration_id
   and f.order_guid = o.order_guid
   and f.rfid = o.rfid
   --and f.order_guid = '735ff8f5-5fbb-48c1-f5d1-a26ec8573cc7'
   and f.rfid='180051769DA2'
join order_payment_types op
on o.id = op.order_id
order by f.created_at asc;


--I want to search the records where rfid_next='180051769DA2'