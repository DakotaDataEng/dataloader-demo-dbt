-- Monthly allocated and field volumes add back to the daily rows they came from.
with monthly as (
    select sum(allocated_oil_bbl) as allocated_oil, sum(allocated_gas_mcf) as allocated_gas, sum(field_oil_bbl) as field_oil
    from {{ ref('fct_production_monthly') }}
), daily as (
    select
        (select sum(allocated_oil_bbl) from {{ ref('fct_production') }}) as allocated_oil,
        (select sum(allocated_gas_mcf) from {{ ref('fct_production') }}) as allocated_gas,
        (select sum(field_oil_bbl) from {{ ref('stg_daily_volumes') }}) as field_oil
)
select monthly.allocated_oil
from monthly cross join daily
where monthly.allocated_oil <> daily.allocated_oil
   or monthly.allocated_gas <> daily.allocated_gas
   or monthly.field_oil <> daily.field_oil
