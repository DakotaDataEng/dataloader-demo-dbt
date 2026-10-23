-- The AFE lines with snake case names.
select
    "AfeLineId" as afe_line_id,
    "AfeId" as afe_id,
    "CostCode" as cost_code,
    "EstimatedAmount" as estimated_amount,
    "ActualAmount" as actual_amount,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'afe_line') }}
