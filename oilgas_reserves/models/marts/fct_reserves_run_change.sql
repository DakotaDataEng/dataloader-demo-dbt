-- How each category moved from one report to the next: remaining Mboe, EUR and PV10 against the report before it.
-- The first report has no earlier one, so its change columns are empty.
select
    category_key,
    run_id,
    as_of_date,
    category,
    remaining_mboe,
    lag(remaining_mboe) over (partition by category order by as_of_date) as prior_remaining_mboe,
    remaining_mboe - lag(remaining_mboe) over (partition by category order by as_of_date) as remaining_mboe_change,
    pv10_usd,
    lag(pv10_usd) over (partition by category order by as_of_date) as prior_pv10_usd,
    pv10_usd - lag(pv10_usd) over (partition by category order by as_of_date) as pv10_usd_change
from {{ ref('fct_reserves_by_category') }}
