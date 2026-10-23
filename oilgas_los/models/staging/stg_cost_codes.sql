-- The cost codes with snake case names.
select
    "CostCode" as cost_code,
    "Description" as description,
    "Category" as category,
    "AccountId" as account_id,
    "DefaultVendorId" as default_vendor_id,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'cost_code') }}
