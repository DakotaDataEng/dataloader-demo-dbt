-- Revenue paid to each owner per month, built from allocated volumes, the Demo prices and the division orders,
-- next to what production accounting reported. A difference other than zero means the two disagree.
with built as (
    select
        owner_id,
        production_month as revenue_month,
        count(distinct well_id) as well_count,
        round(sum(owner_oil_revenue), 2) as oil_revenue,
        round(sum(owner_gas_revenue), 2) as gas_revenue
    from {{ ref('int_owner_well_month') }}
    group by owner_id, production_month
)
select
    b.owner_id,
    o.owner_name,
    o.owner_type,
    b.revenue_month,
    b.well_count,
    b.oil_revenue,
    b.gas_revenue,
    b.oil_revenue + b.gas_revenue as total_revenue,
    r.total_revenue as reported_total_revenue,
    b.oil_revenue + b.gas_revenue - r.total_revenue as difference
from built as b
left join {{ source('land', 'dim_owner') }} as o
    on o.owner_id = b.owner_id
left join {{ ref('stg_monthly_revenue') }} as r
    on r.owner_id = b.owner_id
    and r.revenue_month = b.revenue_month
