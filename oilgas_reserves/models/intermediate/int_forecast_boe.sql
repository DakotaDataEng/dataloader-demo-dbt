-- The monthly forecast with the report, category and well it belongs to, and the month's Mboe.
select
    f.forecast_id,
    f.well_reserve_id,
    r.run_id,
    r.as_of_date,
    r.category,
    r.well_id,
    r.reserve_name,
    f.forecast_month,
    f.oil_mbbl,
    f.gas_mmcf,
    f.oil_mbbl + f.gas_mmcf / 6.0 as forecast_mboe
from {{ ref('stg_forecast_months') }} as f
join {{ ref('int_reserve_rows') }} as r
    on r.well_reserve_id = f.well_reserve_id
