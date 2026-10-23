-- The division orders with snake case names. The raw copy keeps the source's column names, so they are quoted.
select
    "DivisionOrderId" as division_order_id,
    "WellId" as well_id,
    "OwnerId" as owner_id,
    "DecimalInterest" as decimal_interest,
    "EffectiveDate" as effective_date,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'division_order') }}
