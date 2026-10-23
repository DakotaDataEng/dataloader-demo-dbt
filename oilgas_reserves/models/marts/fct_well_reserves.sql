-- Reserves per report, well or location and category: remaining, EUR, development capital and PV10.
select
    well_reserve_id,
    run_id,
    as_of_date,
    category,
    well_id,
    lease_id,
    reserve_name,
    field,
    net_revenue_interest,
    cum_oil_mbbl,
    cum_gas_mmcf,
    remaining_oil_mbbl,
    remaining_gas_mmcf,
    remaining_mboe,
    eur_oil_mbbl,
    eur_gas_mmcf,
    eur_mboe,
    development_capex_usd,
    pv10_usd,
    is_latest_run
from {{ ref('int_reserve_rows') }}
