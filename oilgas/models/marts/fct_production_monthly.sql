-- One row per well per calendar month. Other families (LOS, revenue, land, reserves, financial) read this table for volumes and BOE.
select
    d.well_id,
    w.well_name,
    w.operator,
    w.field,
    cast(date_trunc('month', d.production_date) as date) as production_month,
    count(*) as days_produced,
    sum(d.field_oil_bbl) as field_oil_bbl,
    sum(d.field_gas_mcf) as field_gas_mcf,
    sum(d.allocated_oil_bbl) as allocated_oil_bbl,
    sum(d.allocated_gas_mcf) as allocated_gas_mcf,
    sum(d.allocated_water_bbl) as allocated_water_bbl,
    sum(d.field_boe) as field_boe,
    sum(d.allocated_boe) as allocated_boe
from {{ ref('int_well_days') }} as d
left join {{ ref('stg_wells') }} as w
    on w.well_id = d.well_id
group by d.well_id, w.well_name, w.operator, w.field, cast(date_trunc('month', d.production_date) as date)
