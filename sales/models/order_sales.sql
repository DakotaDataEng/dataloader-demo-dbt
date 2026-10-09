-- One row per non-cancelled order. Historical cost comes from its lines.
with line_totals as (
    select
        l.order_id,
        sum(l.line_amount) as merchandise_revenue,
        sum(l.quantity * l.unit_cost) as merchandise_cost,
        sum(l.quantity) as units_sold,
        count(distinct p.category) as category_count
    from {{ source('demo_raw', 'order_lines') }} l
    join {{ source('demo_raw', 'products') }} p on p.product_id = l.product_id
    group by l.order_id
)
select
    o.order_id,
    o.customer_id,
    cast(o.ordered_at at time zone 'America/Edmonton' as date) as sales_date,
    o.channel,
    c.region,
    o.total_amount as order_revenue,
    coalesce(l.merchandise_revenue, 0) as merchandise_revenue,
    coalesce(l.merchandise_cost, 0) as merchandise_cost,
    coalesce(l.units_sold, 0) as units_sold,
    coalesce(l.category_count, 0) as category_count
from {{ source('demo_raw', 'orders') }} o
join {{ source('demo_raw', 'customers') }} c on c.customer_id = o.customer_id
left join line_totals l on l.order_id = o.order_id
where o.status <> 'cancelled'
