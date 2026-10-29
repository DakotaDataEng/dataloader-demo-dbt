-- Sales for each week, Monday to Sunday, from the daily totals.
select
    cast(date_trunc('week', sales_date) as date) as sales_week,
    sum(order_count) as order_count,
    sum(gross_revenue) as gross_revenue,
    sum(gross_margin) as gross_margin,
    sum(units_sold) as units_sold
from {{ ref('daily_sales') }}
group by 1
