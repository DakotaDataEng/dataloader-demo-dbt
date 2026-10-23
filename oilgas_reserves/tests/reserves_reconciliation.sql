-- EUR equals cumulative plus remaining, remaining equals the sum of the row's forecast months,
-- each report holds 40 PDP rows, and the category totals add up to the well rows.
select 'eur ' || well_reserve_id::text as problem
from {{ ref('stg_well_reserves') }}
where abs(eur_oil_mbbl - (cum_oil_mbbl + remaining_oil_mbbl)) > 0.001
   or abs(eur_gas_mmcf - (cum_gas_mmcf + remaining_gas_mmcf)) > 0.001
union all
select 'forecast ' || r.well_reserve_id::text
from {{ ref('stg_well_reserves') }} as r
join (
    select well_reserve_id, sum(oil_mbbl) as oil, sum(gas_mmcf) as gas
    from {{ ref('stg_forecast_months') }}
    group by well_reserve_id
) as f on f.well_reserve_id = r.well_reserve_id
where abs(r.remaining_oil_mbbl - f.oil) > 0.05 or abs(r.remaining_gas_mmcf - f.gas) > 0.05
union all
select 'category totals'
from (select sum(remaining_mboe) as v from {{ ref('fct_reserves_by_category') }}) c
cross join (select sum(remaining_mboe) as v from {{ ref('fct_well_reserves') }}) w
where abs(c.v - w.v) > 0.001
union all
select 'actuals ' || comparison_key
from {{ ref('fct_reserves_vs_actuals') }}
where abs(oil_variance_mbbl - (actual_oil_mbbl - forecast_oil_mbbl)) > 0.000001
