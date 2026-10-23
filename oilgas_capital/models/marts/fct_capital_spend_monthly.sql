-- Capital invoiced per month and capital cost code, with the number of AFEs and wells it was spent on.
with spend as (
    select
        cast(date_trunc('month', i.invoice_date) as date) as spend_month,
        i.cost_code,
        c.description as cost_code_description,
        count(*) as invoice_count,
        count(distinct i.afe_id) as afe_count,
        count(distinct i.well_id) as well_count,
        sum(i.amount) as amount
    from {{ ref('stg_capital_invoices') }} as i
    left join {{ ref('stg_capital_cost_codes') }} as c
        on c.cost_code = i.cost_code
    group by cast(date_trunc('month', i.invoice_date) as date), i.cost_code, c.description
)
select
    md5(cast(spend_month as text) || '|' || cost_code) as spend_key,
    spend_month,
    cost_code,
    cost_code_description,
    invoice_count,
    afe_count,
    well_count,
    amount
from spend
