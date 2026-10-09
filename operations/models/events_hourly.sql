select
    date_trunc('hour', event_at at time zone 'UTC') as event_hour_utc,
    event_type,
    count(*) as event_count,
    count(distinct session_id) as session_count,
    count(distinct customer_id) as customer_count
from {{ source('demo_raw', 'web_events') }}
group by date_trunc('hour', event_at at time zone 'UTC'), event_type
