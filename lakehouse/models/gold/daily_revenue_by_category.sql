-- Revenue, cost and margin per Edmonton business date and product category.
-- Cancelled orders are left out.
select
    cast(o.ordered_at at time zone 'America/Edmonton' as date) as sales_date,
    p.category,
    count(distinct o.order_id) as order_count,
    sum(l.quantity) as units_sold,
    sum(l.line_amount) as revenue,
    sum(l.quantity * l.unit_cost) as merchandise_cost,
    sum(l.line_amount - l.quantity * l.unit_cost) as gross_margin
from {{ ref('silver_order_lines') }} l
join {{ ref('silver_orders') }} o on o.order_id = l.order_id
join {{ ref('silver_products') }} p on p.product_id = l.product_id
where o.status <> 'cancelled'
group by 1, 2
