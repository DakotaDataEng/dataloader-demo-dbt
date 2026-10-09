select
    sales_date,
    count(*) as order_count,
    count(distinct customer_id) as customer_count,
    sum(order_revenue) as gross_revenue,
    sum(merchandise_revenue) as merchandise_revenue,
    sum(merchandise_cost) as merchandise_cost,
    sum(merchandise_revenue - merchandise_cost) as gross_margin,
    sum(units_sold) as units_sold
from {{ ref('order_sales') }}
group by sales_date
