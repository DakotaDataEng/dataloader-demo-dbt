-- The monthly forecast behind each reserve row, with snake case names.
select
    "ForecastId" as forecast_id,
    "WellReserveId" as well_reserve_id,
    cast("ForecastMonth" as date) as forecast_month,
    "OilMbbl" as oil_mbbl,
    "GasMmcf" as gas_mmcf,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'forecast_month') }}
