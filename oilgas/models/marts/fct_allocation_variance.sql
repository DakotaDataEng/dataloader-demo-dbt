-- Field oil and gas against allocated oil and gas, per well per month. Allocation is what taxes and revenue use.
select
    well_id,
    well_name,
    field,
    production_month,
    field_boe,
    allocated_boe,
    allocated_boe - field_boe as boe_variance,
    case when field_boe = 0 then null else (allocated_boe - field_boe) / field_boe end as boe_variance_rate
from {{ ref('fct_production_monthly') }}
