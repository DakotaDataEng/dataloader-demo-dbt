-- Category revenue adds up to the lines of non-cancelled orders.
with by_category as (
    select coalesce(sum(revenue), 0) as revenue from {{ ref('daily_revenue_by_category') }}
), lines as (
    select coalesce(sum(l.line_amount), 0) as revenue
    from {{ ref('silver_order_lines') }} l
    join {{ ref('silver_orders') }} o on o.order_id = l.order_id
    where o.status <> 'cancelled'
)
select by_category.revenue from by_category cross join lines
where by_category.revenue <> lines.revenue
