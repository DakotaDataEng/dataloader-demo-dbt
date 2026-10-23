-- The partners with snake case names.
select
    "PartnerId" as partner_id,
    "PartnerName" as partner_name,
    "PartnerType" as partner_type,
    "OwnerId" as owner_id,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'partner') }}
