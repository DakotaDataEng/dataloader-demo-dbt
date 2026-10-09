select
    c.customer_id,
    c.demo_name,
    c.region,
    count(s.order_id) as order_count,
    coalesce(sum(s.order_revenue), 0) as lifetime_revenue,
    coalesce(sum(s.merchandise_revenue - s.merchandise_cost), 0) as lifetime_margin,
    min(s.sales_date) as first_order_date,
    max(s.sales_date) as last_order_date
from {{ source('demo_raw', 'customers') }} c
left join {{ ref('order_sales') }} s on s.customer_id = c.customer_id
group by c.customer_id, c.demo_name, c.region
