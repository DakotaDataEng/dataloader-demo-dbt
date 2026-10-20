-- One row per customer with revenue and margin to date. Customers who have
-- never ordered are included with zero totals. Cancelled orders are left out.
with order_totals as (
    select
        o.customer_id,
        count(*) as order_count,
        sum(o.total_amount) as lifetime_revenue,
        sum(coalesce(l.margin, 0)) as lifetime_margin,
        min(cast(o.ordered_at at time zone 'America/Edmonton' as date)) as first_order_date,
        max(cast(o.ordered_at at time zone 'America/Edmonton' as date)) as last_order_date
    from {{ ref('silver_orders') }} o
    left join (
        select order_id, sum(line_amount - quantity * unit_cost) as margin
        from {{ ref('silver_order_lines') }}
        group by order_id
    ) l on l.order_id = o.order_id
    where o.status <> 'cancelled'
    group by o.customer_id
)
select
    c.customer_id,
    c.customer_name,
    c.region,
    coalesce(t.order_count, 0) as order_count,
    coalesce(t.lifetime_revenue, 0) as lifetime_revenue,
    coalesce(t.lifetime_margin, 0) as lifetime_margin,
    t.first_order_date,
    t.last_order_date
from {{ ref('silver_customers') }} c
left join order_totals t on t.customer_id = c.customer_id
