-- Hours from order to shipment and to delivery, per Edmonton order date.
-- Cancelled orders are left out. A delivery is late when it arrives after
-- the promised time. Shipments not yet delivered count in the shipped
-- columns only.
select
    cast(o.ordered_at at time zone 'America/Edmonton' as date) as order_date,
    count(*) as shipment_count,
    avg(date_diff('minute', o.ordered_at, s.shipped_at) / 60.0) as avg_hours_to_ship,
    count(s.delivered_at) as delivered_count,
    avg(date_diff('minute', o.ordered_at, s.delivered_at) / 60.0) as avg_hours_to_deliver,
    count(*) filter (where s.delivered_at > s.expected_delivery_at) as late_delivery_count
from {{ ref('silver_shipments') }} s
join {{ ref('silver_orders') }} o on o.order_id = s.order_id
where o.status <> 'cancelled'
group by 1
