{{ config(enabled=target.name == 'prod') }}

select
    concat_ws('|', event_at::date::text, coalesce(event_type, '<null>')) as event_day_type_key,
    event_at::date as event_date,
    event_type,
    count(*) as event_count
from {{ source('sandbox_raw', 'order_events') }}
group by event_at::date, event_type
