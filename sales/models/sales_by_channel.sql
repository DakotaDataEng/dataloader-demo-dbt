-- Sales for each channel: orders, revenue and units.
select
    channel,
    count(*) as order_count,
    sum(order_revenue) as gross_revenue,
    sum(unit_count) as unit_count
from {{ ref('order_sales') }}
group by channel
