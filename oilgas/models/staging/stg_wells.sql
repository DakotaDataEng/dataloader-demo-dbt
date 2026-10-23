-- The well list with snake case names. The raw copy keeps the source's column names, so they are quoted.
select
    "WellId" as well_id,
    "ApiNumber" as api_number,
    "WellName" as well_name,
    "Operator" as operator,
    "Field" as field,
    "SpudDate" as spud_date,
    "Status" as status,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'well') }}
