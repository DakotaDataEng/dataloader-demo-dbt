-- Each owner's share of each well's value per month, from the division order's decimal interest. Not rounded.
select
    d.owner_id,
    v.well_id,
    v.production_month,
    d.decimal_interest,
    v.oil_value * d.decimal_interest as owner_oil_revenue,
    v.gas_value * d.decimal_interest as owner_gas_revenue
from {{ ref('int_well_month_value') }} as v
join {{ ref('stg_division_orders') }} as d
    on d.well_id = v.well_id
