-- Gross (8/8ths) oil and gas revenue per well per month at the Demo prices, before any owner's share. Netback reads it.
select
    well_id,
    well_name,
    field,
    production_month,
    allocated_oil_bbl,
    allocated_gas_mcf,
    allocated_boe,
    oil_price_usd_bbl,
    gas_price_usd_mcf,
    round(oil_value, 2) as oil_revenue,
    round(gas_value, 2) as gas_revenue,
    round(oil_value, 2) + round(gas_value, 2) as gross_revenue
from {{ ref('int_well_month_value') }}
