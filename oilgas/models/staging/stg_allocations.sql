-- The allocation load with snake case names. The raw copy keeps the source's column names, so they are quoted.
select
    "AllocationId" as allocation_id,
    "WellId" as well_id,
    "ProductionDate" as production_date,
    "AllocatedOilBbl" as allocated_oil_bbl,
    "AllocatedGasMcf" as allocated_gas_mcf,
    "AllocatedWaterBbl" as allocated_water_bbl,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'daily_allocation') }}
