with collections as (
    select
        cast(p.paid_at at time zone 'America/Edmonton' as date) as revenue_date,
        sum(p.amount) as collected_revenue,
        count(*) as payment_count
    from {{ source('demo_raw', 'payments') }} p
    join {{ source('sales', 'order_sales') }} s on s.order_id = p.order_id
    where p.status = 'settled'
    group by cast(p.paid_at at time zone 'America/Edmonton' as date)
)
select
    coalesce(s.sales_date, c.revenue_date) as revenue_date,
    coalesce(s.gross_revenue, 0) as booked_revenue,
    coalesce(c.collected_revenue, 0) as collected_revenue,
    coalesce(c.payment_count, 0) as payment_count,
    coalesce(s.order_count, 0) as order_count
from {{ source('sales', 'daily_sales') }} s
full outer join collections c on c.revenue_date = s.sales_date
