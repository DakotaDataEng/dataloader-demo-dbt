-- Allocated volumes per lease per month, added up from the wells on the lease. Reads the volumes project.
select
    lw.lease_id,
    lw.lease_name,
    lw.county,
    p.production_month,
    count(distinct p.well_id) as producing_wells,
    sum(p.allocated_oil_bbl) as allocated_oil_bbl,
    sum(p.allocated_gas_mcf) as allocated_gas_mcf,
    sum(p.allocated_boe) as allocated_boe
from {{ source('volumes', 'fct_production_monthly') }} as p
join {{ ref('int_lease_wells') }} as lw
    on lw.well_id = p.well_id
group by lw.lease_id, lw.lease_name, lw.county, p.production_month
