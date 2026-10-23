-- The whole operator's lease operating statement per month, with G&A, and LOS per BOE on all volumes.
with costs as (
    select
        los_month,
        sum(case when category = 'LOE' then amount else 0 end) as loe_cost,
        sum(case when category = 'Workover' then amount else 0 end) as workover_cost,
        sum(case when category = 'Tax' then amount else 0 end) as production_tax_cost,
        sum(case when category = 'G&A' then amount else 0 end) as ga_cost
    from {{ ref('fct_los_monthly') }}
    group by los_month
), volumes as (
    select production_month, sum(allocated_boe) as allocated_boe
    from {{ source('volumes', 'fct_production_monthly') }}
    group by production_month
)
select
    v.production_month as los_month,
    v.allocated_boe,
    coalesce(c.loe_cost, 0) as loe_cost,
    coalesce(c.workover_cost, 0) as workover_cost,
    coalesce(c.production_tax_cost, 0) as production_tax_cost,
    coalesce(c.ga_cost, 0) as ga_cost,
    coalesce(c.loe_cost, 0) + coalesce(c.workover_cost, 0) + coalesce(c.production_tax_cost, 0) + coalesce(c.ga_cost, 0) as total_los_cost,
    case when v.allocated_boe = 0 then null
         else (coalesce(c.loe_cost, 0) + coalesce(c.workover_cost, 0) + coalesce(c.production_tax_cost, 0) + coalesce(c.ga_cost, 0)) / v.allocated_boe
    end as los_per_boe
from volumes as v
left join costs as c
    on c.los_month = v.production_month
