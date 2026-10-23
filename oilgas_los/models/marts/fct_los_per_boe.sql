-- LOS cost per BOE per well per month. Reads the volumes project for the BOE.
-- Well costs only: LOE, workover and production taxes. G&A has no well, see fct_los_summary_monthly.
with costs as (
    select
        well_id,
        los_month,
        sum(case when category = 'LOE' then amount else 0 end) as loe_cost,
        sum(case when category = 'Workover' then amount else 0 end) as workover_cost,
        sum(case when category = 'Tax' then amount else 0 end) as production_tax_cost
    from {{ ref('fct_los_monthly') }}
    where well_id is not null
    group by well_id, los_month
)
select
    p.well_id,
    p.well_name,
    p.field,
    p.production_month as los_month,
    p.allocated_boe,
    coalesce(c.loe_cost, 0) as loe_cost,
    coalesce(c.workover_cost, 0) as workover_cost,
    coalesce(c.production_tax_cost, 0) as production_tax_cost,
    coalesce(c.loe_cost, 0) + coalesce(c.workover_cost, 0) + coalesce(c.production_tax_cost, 0) as total_los_cost,
    case when p.allocated_boe = 0 then null else coalesce(c.loe_cost, 0) / p.allocated_boe end as loe_per_boe,
    case when p.allocated_boe = 0 then null
         else (coalesce(c.loe_cost, 0) + coalesce(c.workover_cost, 0) + coalesce(c.production_tax_cost, 0)) / p.allocated_boe
    end as los_per_boe
from {{ source('volumes', 'fct_production_monthly') }} as p
left join costs as c
    on c.well_id = p.well_id
    and c.los_month = p.production_month
