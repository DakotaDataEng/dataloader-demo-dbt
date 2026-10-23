-- One row per AFE: estimate, actual and variance added up over its lines.
select
    afe_id,
    afe_number,
    well_id,
    lease_id,
    lease_name,
    afe_type,
    afe_status,
    count(*) as line_count,
    sum(estimated_amount) as estimated_amount,
    sum(actual_amount) as actual_amount,
    sum(variance_amount) as variance_amount,
    case when sum(estimated_amount) = 0 then null else sum(variance_amount) / sum(estimated_amount) end as variance_rate,
    sum(invoice_count) as invoice_count
from {{ ref('fct_afe_variance') }}
group by afe_id, afe_number, well_id, lease_id, lease_name, afe_type, afe_status
