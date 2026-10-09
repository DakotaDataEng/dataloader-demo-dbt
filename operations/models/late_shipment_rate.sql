with shipment_status as (
    select
        shipment_id,
        carrier,
        cast(expected_delivery_at at time zone 'America/Edmonton' as date) as expected_date,
        case when status = 'cancelled' then false
             when delivered_at is not null then delivered_at > expected_delivery_at
             else current_timestamp > expected_delivery_at end as is_late
    from {{ source('demo_raw', 'shipments') }}
    where expected_delivery_at is not null and status <> 'cancelled'
)
select
    expected_date,
    carrier,
    count(*) as shipment_count,
    sum(case when is_late then 1 else 0 end) as late_count,
    sum(case when is_late then 1 else 0 end)::numeric / count(*) as late_rate
from shipment_status
group by expected_date, carrier
