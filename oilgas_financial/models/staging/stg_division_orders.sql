-- The division orders with snake case names. Used to find the royalty owners of each well.
select
    "DivisionOrderId" as division_order_id,
    "WellId" as well_id,
    "OwnerId" as owner_id,
    "DecimalInterest" as decimal_interest
from {{ source('og_raw', 'division_order') }}
