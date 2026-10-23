-- One row per well per production day with what the field measured next to what production accounting allocated.
-- A day can exist on one side only while a load is catching up, so the two sides are joined in full.
select
    coalesce(v.well_id, a.well_id) as well_id,
    coalesce(v.production_date, a.production_date) as production_date,
    v.field_oil_bbl,
    v.field_gas_mcf,
    v.field_water_bbl,
    a.allocated_oil_bbl,
    a.allocated_gas_mcf,
    a.allocated_water_bbl,
    -- BOE (barrel of oil equivalent) is oil plus gas at 6 Mcf per barrel.
    coalesce(v.field_oil_bbl, 0) + coalesce(v.field_gas_mcf, 0) / 6.0 as field_boe,
    coalesce(a.allocated_oil_bbl, 0) + coalesce(a.allocated_gas_mcf, 0) / 6.0 as allocated_boe
from {{ ref('stg_daily_volumes') }} as v
full join {{ ref('stg_allocations') }} as a
    on a.well_id = v.well_id
    and a.production_date = v.production_date
