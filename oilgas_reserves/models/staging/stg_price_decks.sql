-- The price decks with snake case names.
select
    "PriceDeckId" as price_deck_id,
    "RunId" as run_id,
    "DeckYear" as deck_year,
    "OilPriceUsdBbl" as oil_price_usd_bbl,
    "GasPriceUsdMcf" as gas_price_usd_mcf,
    "OilDifferentialUsdBbl" as oil_differential_usd_bbl,
    "GasDifferentialUsdMcf" as gas_differential_usd_mcf,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'price_deck') }}
