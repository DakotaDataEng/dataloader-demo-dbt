-- One row per well per production day: the allocated volumes with the well they belong to.
select
    a.allocation_id,
    a.well_id,
    w."ApiNumber" as api_number,
    w."WellName" as well_name,
    w."Field" as field,
    a.production_date,
    a.allocated_oil_bbl,
    a.allocated_gas_mcf,
    a.allocated_water_bbl,
    a.modified_at
from {{ ref('stg_allocations') }} as a
left join {{ source('og_raw', 'well') }} as w
    on w."WellId" = a.well_id
