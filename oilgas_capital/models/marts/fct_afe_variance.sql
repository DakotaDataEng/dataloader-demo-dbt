-- AFE variance by AFE and cost code: actual less estimate. Positive means over the estimate, negative means under.
-- The actual is the one accounting keeps on the AFE line. invoiced_amount is the capital invoices behind it, so the two can be checked.
select
    x.afe_line_id,
    x.afe_id,
    x.afe_number,
    x.well_id,
    x.lease_id,
    d.lease_name,
    x.afe_type,
    x.afe_status,
    x.cost_code,
    x.cost_code_description,
    x.estimated_amount,
    x.actual_amount,
    x.actual_amount - x.estimated_amount as variance_amount,
    case when x.estimated_amount = 0 then null
         else (x.actual_amount - x.estimated_amount) / x.estimated_amount end as variance_rate,
    case
        when x.actual_amount > x.estimated_amount then 'Over'
        when x.actual_amount < x.estimated_amount then 'Under'
        else 'On estimate'
    end as variance_direction,
    x.invoiced_amount,
    x.invoice_count
from {{ ref('int_afe_lines') }} as x
left join {{ source('land', 'dim_lease') }} as d
    on d.lease_id = x.lease_id
