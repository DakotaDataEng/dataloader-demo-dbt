-- The AFEs with snake case names. The raw copy keeps the source's column names, so they are quoted.
select
    "AfeId" as afe_id,
    "AfeNumber" as afe_number,
    "WellId" as well_id,
    "LeaseId" as lease_id,
    "AfeType" as afe_type,
    "Description" as description,
    "ApprovedDate" as approved_date,
    "Status" as status,
    "ClosedDate" as closed_date,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'afe') }}
