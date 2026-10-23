-- Reserves per report and category (PDP, PDNP, PUD): rows, remaining volumes, EUR, development capital and PV10.
select
    md5(cast(run_id as text) || '|' || category) as category_key,
    run_id,
    as_of_date,
    run_name,
    category,
    count(*) as reserve_row_count,
    sum(remaining_oil_mbbl) as remaining_oil_mbbl,
    sum(remaining_gas_mmcf) as remaining_gas_mmcf,
    sum(remaining_mboe) as remaining_mboe,
    sum(eur_mboe) as eur_mboe,
    sum(development_capex_usd) as development_capex_usd,
    sum(pv10_usd) as pv10_usd,
    max(is_latest_run::int)::boolean as is_latest_run
from {{ ref('int_reserve_rows') }}
group by run_id, as_of_date, run_name, category
