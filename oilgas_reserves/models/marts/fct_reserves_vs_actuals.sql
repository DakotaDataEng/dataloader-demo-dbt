-- Forecast against actual production per report, well and month, for the months the volumes project holds.
-- The actual is the allocated volume from the volumes project, which traces back to field data capture.
-- Only wells with a forecast and actual volumes appear: PDP wells in the months after the as-of date. A month at the edge of the history can be partial, see is_full_month.
select
    md5(cast(f.run_id as text) || '|' || cast(f.well_id as text) || '|' || cast(f.forecast_month as text)) as comparison_key,
    f.run_id,
    f.as_of_date,
    f.well_id,
    f.reserve_name,
    f.category,
    f.forecast_month,
    a.days_produced,
    extract(day from (f.forecast_month + interval '1 month' - f.forecast_month))::int as days_in_month,
    a.days_produced = extract(day from (f.forecast_month + interval '1 month' - f.forecast_month))::int as is_full_month,
    f.oil_mbbl as forecast_oil_mbbl,
    a.allocated_oil_bbl / 1000.0 as actual_oil_mbbl,
    a.allocated_oil_bbl / 1000.0 - f.oil_mbbl as oil_variance_mbbl,
    case when f.oil_mbbl = 0 then null else (a.allocated_oil_bbl / 1000.0 - f.oil_mbbl) / f.oil_mbbl end as oil_variance_rate,
    f.forecast_mboe,
    a.allocated_boe / 1000.0 as actual_mboe,
    a.allocated_boe / 1000.0 - f.forecast_mboe as mboe_variance
from {{ ref('int_forecast_boe') }} as f
join {{ source('volumes', 'fct_production_monthly') }} as a
    on a.well_id = f.well_id
    and a.production_month = f.forecast_month
