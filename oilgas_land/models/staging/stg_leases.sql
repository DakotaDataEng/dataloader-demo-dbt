-- The lease list with snake case names. The raw copy keeps the source's column names, so they are quoted.
select
    "LeaseId" as lease_id,
    "LeaseName" as lease_name,
    "County" as county,
    "Acres" as acres,
    "EffectiveDate" as effective_date,
    "ExpiryDate" as expiry_date,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'lease') }}
