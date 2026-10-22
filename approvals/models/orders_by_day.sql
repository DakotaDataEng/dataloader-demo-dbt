{{ config(materialized='incremental', unique_key='day_channel') }}
-- One row per Edmonton business day and channel. An incremental run rebuilds
-- the last two days, so late orders land on the right row.
select
    cast(ordered_at at time zone 'America/Edmonton' as date) || '|' || channel as day_channel,
    cast(ordered_at at time zone 'America/Edmonton' as date) as order_date,
    channel,
    count(*) as order_count,
    sum(total_amount) as order_revenue
from {{ source('demo_raw', 'orders') }}
{% if is_incremental() %}
where cast(ordered_at at time zone 'America/Edmonton' as date)
    >= (select max(order_date) - 1 from {{ this }})
{% endif %}
group by 1, 2, 3
