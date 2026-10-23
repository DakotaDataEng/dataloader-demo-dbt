-- The vendors with snake case names.
select
    "VendorId" as vendor_id,
    "VendorName" as vendor_name,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'vendor') }}
