{{ config(enabled=target.name == 'prod') }}

select
    concat_ws('|', order_date::text, coalesce(status, '<null>'), coalesce(currency, '<null>')) as order_day_status_currency_key,
    order_date,
    status,
    currency,
    count(*) as order_count,
    sum(amount) as order_amount
from {{ source('sandbox_raw', 'orders') }}
group by order_date, status, currency
