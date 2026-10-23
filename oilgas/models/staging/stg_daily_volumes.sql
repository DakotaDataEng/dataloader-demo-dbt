-- The volumes measured in the field, with snake case names.
select
    "VolumeId" as volume_id,
    "WellId" as well_id,
    "ProductionDate" as production_date,
    "OilBbl" as field_oil_bbl,
    "GasMcf" as field_gas_mcf,
    "WaterBbl" as field_water_bbl,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'daily_volume') }}
