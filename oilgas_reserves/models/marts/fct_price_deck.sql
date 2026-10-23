-- The price deck of each report by calendar year, with the realized price after the differential.
select
    d.price_deck_id,
    d.run_id,
    r.as_of_date,
    r.price_deck_name,
    d.deck_year,
    d.oil_price_usd_bbl,
    d.oil_differential_usd_bbl,
    d.oil_price_usd_bbl - d.oil_differential_usd_bbl as oil_realized_usd_bbl,
    d.gas_price_usd_mcf,
    d.gas_differential_usd_mcf,
    d.gas_price_usd_mcf - d.gas_differential_usd_mcf as gas_realized_usd_mcf
from {{ ref('stg_price_decks') }} as d
join {{ ref('stg_reserve_runs') }} as r
    on r.run_id = d.run_id
