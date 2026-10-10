{{ config(enabled=target.name == 'prod') }}

select
    concat_ws('|', coalesce(c.segment, '<null>'), coalesce(c.country, '<null>'), coalesce(o.currency, '<null>')) as segment_country_currency_key,
    c.segment,
    c.country,
    o.currency,
    count(distinct o.order_id) as order_count,
    coalesce(sum(o.amount), 0) as order_amount
from {{ source('sandbox_raw', 'customers') }} c
left join {{ source('sandbox_raw', 'orders') }} o on o.customer_id = c.customer_id
group by c.segment, c.country, o.currency
