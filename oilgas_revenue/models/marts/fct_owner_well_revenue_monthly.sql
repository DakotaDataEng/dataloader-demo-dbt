-- Revenue paid to each owner from each well per month, at the Demo prices and the division order's decimal interest.
-- Financial reads it to check the royalty it takes off a well's revenue.
select
    md5(cast(owner_id as text) || '|' || cast(well_id as text) || '|' || cast(production_month as text)) as owner_well_key,
    owner_id,
    well_id,
    production_month,
    decimal_interest,
    round(owner_oil_revenue, 2) as oil_revenue,
    round(owner_gas_revenue, 2) as gas_revenue,
    round(owner_oil_revenue + owner_gas_revenue, 2) as total_revenue
from {{ ref('int_owner_well_month') }}
