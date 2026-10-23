-- One row per AFE line with the AFE it belongs to, the cost code's name and the invoices charged to it.
select
    l.afe_line_id,
    l.afe_id,
    a.afe_number,
    a.well_id,
    a.lease_id,
    a.afe_type,
    a.status as afe_status,
    a.approved_date,
    a.closed_date,
    l.cost_code,
    c.description as cost_code_description,
    l.estimated_amount,
    l.actual_amount,
    coalesce(i.invoiced_amount, 0) as invoiced_amount,
    coalesce(i.invoice_count, 0) as invoice_count,
    i.last_invoice_date
from {{ ref('stg_afe_lines') }} as l
join {{ ref('stg_afes') }} as a
    on a.afe_id = l.afe_id
left join {{ ref('stg_capital_cost_codes') }} as c
    on c.cost_code = l.cost_code
left join {{ ref('int_afe_line_invoices') }} as i
    on i.afe_id = l.afe_id
    and i.cost_code = l.cost_code
