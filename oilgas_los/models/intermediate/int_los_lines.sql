-- The invoices that make up a lease operating statement: LOE, workover, production taxes and G&A.
-- Capital invoices belong to the capital family and are left out.
-- Production taxes are invoiced on the 1st of the month after the production they tax, so they are placed in the production month.
select
    i.ap_invoice_id,
    i.invoice_number,
    i.well_id,
    i.lease_id,
    i.cost_code,
    c.description as los_line,
    c.category,
    v.vendor_name,
    i.invoice_date,
    case
        when c.category = 'Tax' then cast(date_trunc('month', i.invoice_date) - interval '1 month' as date)
        else cast(date_trunc('month', i.invoice_date) as date)
    end as los_month,
    i.amount
from {{ ref('stg_ap_invoices') }} as i
join {{ ref('stg_cost_codes') }} as c
    on c.cost_code = i.cost_code
left join {{ ref('stg_vendors') }} as v
    on v.vendor_id = i.vendor_id
where c.category in ('LOE', 'Workover', 'Tax', 'G&A')
