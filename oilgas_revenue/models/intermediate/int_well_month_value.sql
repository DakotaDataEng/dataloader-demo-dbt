-- The gross value of each well's allocated volumes per month at the flat Demo prices. Not rounded: marts round at the end.
select
    p.well_id,
    p.well_name,
    p.field,
    p.production_month,
    p.allocated_oil_bbl,
    p.allocated_gas_mcf,
    p.allocated_boe,
    {{ var('demo_oil_price_usd_bbl') }} as oil_price_usd_bbl,
    {{ var('demo_gas_price_usd_mcf') }} as gas_price_usd_mcf,
    p.allocated_oil_bbl * {{ var('demo_oil_price_usd_bbl') }} as oil_value,
    p.allocated_gas_mcf * {{ var('demo_gas_price_usd_mcf') }} as gas_value
from {{ source('volumes', 'fct_production_monthly') }} as p
