-- The reserves per report, well and category with snake case names. Volumes are gross, in Mbbl and MMcf.
select
    "WellReserveId" as well_reserve_id,
    "RunId" as run_id,
    "WellId" as well_id,
    "LeaseId" as lease_id,
    "LocationName" as location_name,
    "Category" as category,
    "NetRevenueInterest" as net_revenue_interest,
    "CumOilMbbl" as cum_oil_mbbl,
    "CumGasMmcf" as cum_gas_mmcf,
    "RemainingOilMbbl" as remaining_oil_mbbl,
    "RemainingGasMmcf" as remaining_gas_mmcf,
    "EurOilMbbl" as eur_oil_mbbl,
    "EurGasMmcf" as eur_gas_mmcf,
    "DevelopmentCapexUsd" as development_capex_usd,
    "Pv10Usd" as pv10_usd,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'well_reserve') }}
