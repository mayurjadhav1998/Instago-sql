with tbl as (
    select order_guid, count(*)
    from service_requests sr
    where sr.created_at > '2024-07-11 00:00:01'
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
    from service_requests sr
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
           substring(regexp_replace(split_part(t1.response, ':registration_id:', 2), '[^0-9a-f\-]', '', 'g'),1,36) as registration_id,
           substring(regexp_replace(split_part(t1.response, ':rfid_number:', 2), '[^0-9A-F]', '', 'g'), 1, 12) as rfid,
           substring(regexp_replace(split_part(t2.response, ':registration_id:', 2), '[^0-9a-f\-]', '', 'g'),1,36) as registration_id_next,
           substring(regexp_replace(split_part(t2.response, ':rfid_number:', 2), '[^0-9A-F]', '', 'g'), 1, 12) as rfid_next
    from tbl1 t1
    left join tbl1 t2
    on t1.order_guid = t2.order_guid and t1.rn = t2.rn - 1
)

select *,
       (rfid_amount - rfid_amount_next) as sold_product_amount,
       (rfid_amount - rfid_amount_next) * rn as sold_product_amount_mul
from tbl2
where rfid_amount <> rfid_amount_next
  and responsenext is not null
  and registration_id = registration_id_next
  and rfid = rfid_next
order by created_at asc;
