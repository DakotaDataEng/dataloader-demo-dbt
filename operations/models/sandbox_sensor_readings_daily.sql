{{ config(enabled=target.name == 'prod') }}

select
    concat_ws('|', reading_at::date::text, coalesce(device_id, '<null>'), coalesce(quality::text, '<null>')) as device_day_quality_key,
    reading_at::date as reading_date,
    device_id,
    quality,
    count(*) as reading_count,
    min(value) as minimum_value,
    max(value) as maximum_value,
    avg(value) as average_value
from {{ source('sandbox_raw', 'sensor_readings') }}
group by reading_at::date, device_id, quality
