-- The owner list with snake case names.
select
    "OwnerId" as owner_id,
    "OwnerName" as owner_name,
    "OwnerType" as owner_type,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'owner') }}
