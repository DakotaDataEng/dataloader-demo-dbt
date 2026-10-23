-- The capital cost codes (CAP100 drilling to CAP400 pipeline), with snake case names.
select
    "CostCode" as cost_code,
    "Description" as description,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'cost_code') }}
where "Category" = 'Capital'
