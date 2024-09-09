select *
,sr.registration_id ,
parameter_details ,response,failure_reason,action,request_status
from service_requests sr 
join orders o on sr.order_guid =o.order_guid
where date(o.created_at)>=$start_date
and date(o.created_at)<=$end_date and 
o.registration_id ='2627cde8-b712-4aa2-b981-4a8f6b4bdea2'
--and DATE(o.created_at)=$start_date
--and dispensing='started'
--and dispensing is null
and action='add_and_deduct_amount_in_rfid'

--
--select * 
--from cash_infos ci 
--where machine_id =572
--and date(created_at)>='2024-08-01'
--and date(created_at)<='2024-08-31'


