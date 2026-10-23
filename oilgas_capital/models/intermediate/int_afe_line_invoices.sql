-- Capital invoices added up per AFE and cost code. This is the accounting side of an AFE line's actual.
select
    afe_id,
    cost_code,
    count(*) as invoice_count,
    sum(amount) as invoiced_amount,
    min(invoice_date) as first_invoice_date,
    max(invoice_date) as last_invoice_date
from {{ ref('stg_capital_invoices') }}
where afe_id is not null
group by afe_id, cost_code
