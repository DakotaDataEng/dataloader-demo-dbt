with totals as (
    select coalesce(sum(order_revenue), 0) as revenue from {{ ref('order_sales') }}
), daily as (
    select coalesce(sum(gross_revenue), 0) as revenue from {{ ref('daily_sales') }}
), customers as (
    select coalesce(sum(lifetime_revenue), 0) as revenue from {{ ref('customer_lifetime_value') }}
)
select totals.revenue from totals cross join daily cross join customers
where totals.revenue <> daily.revenue or totals.revenue <> customers.revenue
