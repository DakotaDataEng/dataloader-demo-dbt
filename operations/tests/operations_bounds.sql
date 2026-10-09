select 'stock' as problem from {{ ref('stock_levels') }} where on_hand < 0 or reorder_level < 0
union all
select 'shipments' from {{ ref('late_shipment_rate') }} where late_rate < 0 or late_rate > 1
union all
select 'events' from {{ ref('events_hourly') }} where event_count < session_count
