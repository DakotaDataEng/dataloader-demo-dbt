-- One row per reserve row (report, well or location, category) with the report's dates and the well's name and field from the volumes project.
-- Mboe is thousand barrels of oil equivalent: Mbbl of oil plus MMcf of gas divided by 6.
select
    r.well_reserve_id,
    r.run_id,
    u.as_of_date,
    u.issued_date,
    u.run_name,
    r.category,
    r.well_id,
    r.lease_id,
    coalesce(w.well_name, r.location_name) as reserve_name,
    r.location_name,
    w.field,
    r.net_revenue_interest,
    r.cum_oil_mbbl,
    r.cum_gas_mmcf,
    r.remaining_oil_mbbl,
    r.remaining_gas_mmcf,
    r.remaining_oil_mbbl + r.remaining_gas_mmcf / 6.0 as remaining_mboe,
    r.eur_oil_mbbl,
    r.eur_gas_mmcf,
    r.eur_oil_mbbl + r.eur_gas_mmcf / 6.0 as eur_mboe,
    r.development_capex_usd,
    r.pv10_usd,
    r.run_id = max(r.run_id) over () as is_latest_run
from {{ ref('stg_well_reserves') }} as r
join {{ ref('stg_reserve_runs') }} as u
    on u.run_id = r.run_id
left join {{ source('volumes', 'dim_well') }} as w
    on w.well_id = r.well_id
