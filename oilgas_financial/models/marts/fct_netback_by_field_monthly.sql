-- Netback per field per month, added up from the wells, with netback per BOE on the field's volumes.
select
    field,
    production_month,
    count(*) as well_count,
    sum(allocated_boe) as allocated_boe,
    sum(gross_revenue) as gross_revenue,
    sum(royalty_cost) as royalty_cost,
    sum(loe_cost + workover_cost + production_tax_cost) as total_los_cost,
    sum(netback) as netback,
    case when sum(allocated_boe) = 0 then null else sum(netback) / sum(allocated_boe) end as netback_per_boe
from {{ ref('fct_netback_monthly') }}
group by field, production_month
