{{ config(materialized='incremental', unique_key='order_id') }}
-- Orders from the 30 days up to the newest order. Each run adds new orders and updates the ones that changed since the last run.
select
    order_id,
    customer_id,
    ordered_at,
    status,
    channel,
    total_amount,
    updated_at
from {{ source('demo_raw', 'orders') }}
where ordered_at >= (select max(ordered_at) from {{ source('demo_raw', 'orders') }}) - interval '30 days'
{% if is_incremental() %}
    and updated_at > (select max(updated_at) from {{ this }})
{% endif %}
