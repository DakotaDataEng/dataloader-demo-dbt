-- Sales for each province and channel, with how many product categories an order usually holds.
select
    region,
    channel,
    count(*) as order_count,
    sum(order_revenue) as gross_revenue,
    sum(unit_count) as units_sold,
    avg(category_count) as average_categories
from {{ ref('order_sales') }}
group by region, channel
