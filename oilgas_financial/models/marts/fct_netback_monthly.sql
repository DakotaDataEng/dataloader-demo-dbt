-- Operating netback per well per month: gross revenue less LOE, workover and production taxes, and the same per BOE.
-- It reads the revenue project for revenue, the LOS project for costs and the volumes project for BOE.
-- G&A has no well, so it is not in a well's netback.
select
    v.well_id,
    v.well_name,
    v.field,
    v.production_month,
    v.allocated_boe,
    coalesce(r.gross_revenue, 0) as gross_revenue,
    coalesce(l.loe_cost, 0) as loe_cost,
    coalesce(l.workover_cost, 0) as workover_cost,
    coalesce(l.production_tax_cost, 0) as production_tax_cost,
    coalesce(r.gross_revenue, 0) - coalesce(l.loe_cost, 0) - coalesce(l.workover_cost, 0) - coalesce(l.production_tax_cost, 0) as netback,
    case when v.allocated_boe = 0 then null else coalesce(r.gross_revenue, 0) / v.allocated_boe end as revenue_per_boe,
    case when v.allocated_boe = 0 then null
         else (coalesce(l.loe_cost, 0) + coalesce(l.workover_cost, 0) + coalesce(l.production_tax_cost, 0)) / v.allocated_boe
    end as los_per_boe,
    case when v.allocated_boe = 0 then null
         else (coalesce(r.gross_revenue, 0) - coalesce(l.loe_cost, 0) - coalesce(l.workover_cost, 0) - coalesce(l.production_tax_cost, 0)) / v.allocated_boe
    end as netback_per_boe
from {{ source('volumes', 'fct_production_monthly') }} as v
left join {{ source('revenue', 'fct_well_revenue_monthly') }} as r
    on r.well_id = v.well_id
    and r.production_month = v.production_month
left join {{ source('los', 'fct_los_per_boe') }} as l
    on l.well_id = v.well_id
    and l.los_month = v.production_month
