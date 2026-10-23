-- The owners' interests in each lease, with snake case names.
select
    "LeaseInterestId" as lease_interest_id,
    "LeaseId" as lease_id,
    "OwnerId" as owner_id,
    "DecimalInterest" as decimal_interest,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'lease_interest') }}
