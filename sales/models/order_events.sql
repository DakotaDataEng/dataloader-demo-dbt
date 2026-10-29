{{ config(materialized='incremental', unique_key='order_id', on_schema_change='append_new_columns') }}
-- The latest state of every order. Each run adds new orders and updates the ones that changed since the last run.
select
    order_id,
    customer_id,
    status,
    channel,
    total_amount,
    updated_at
from {{ source('demo_raw', 'orders') }}
{% if is_incremental() %}
where updated_at > (select max(updated_at) from {{ this }})
{% endif %}
