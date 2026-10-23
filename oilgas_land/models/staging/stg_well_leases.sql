-- The well to lease link kept by accounting, with snake case names. Read the lease from here, never recompute it from the well number.
select
    "WellId" as well_id,
    "LeaseId" as lease_id,
    "CostCenter" as cost_center,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'well_lease') }}
