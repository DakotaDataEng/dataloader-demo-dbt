-- One row per well per production day: the allocated volumes with the well they belong to.
select
    a.allocation_id,
    a.well_id,
    w.api_number,
    w.well_name,
    w.field,
    a.production_date,
    a.allocated_oil_bbl,
    a.allocated_gas_mcf,
    a.allocated_water_bbl,
    a.modified_at
from {{ ref('stg_allocations') }} as a
left join {{ ref('stg_wells') }} as w
    on w.well_id = a.well_id
