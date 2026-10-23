-- The reserves reports with snake case names. The raw copy keeps the source's column names, so they are quoted.
select
    "RunId" as run_id,
    "AsOfDate" as as_of_date,
    "IssuedDate" as issued_date,
    "RunName" as run_name,
    "PriceDeckName" as price_deck_name,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'reserve_run') }}
