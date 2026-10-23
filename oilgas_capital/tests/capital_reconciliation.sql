-- AFE variance equals actual less estimate, an AFE line's actual equals the capital invoices charged to it, and the AFE totals add up from their lines.
select afe_line_id::text as problem
from {{ ref('fct_afe_variance') }}
where variance_amount <> actual_amount - estimated_amount
   or actual_amount <> invoiced_amount
union all
select afe_id::text
from {{ ref('fct_afe_summary') }}
where variance_amount <> actual_amount - estimated_amount
union all
select 'summary total'
from (select sum(variance_amount) as v from {{ ref('fct_afe_summary') }}) s
cross join (select sum(variance_amount) as v from {{ ref('fct_afe_variance') }}) l
where s.v <> l.v
union all
select 'capital invoices'
from (select sum(amount) as a from {{ ref('fct_capital_spend_monthly') }}) m
cross join (select sum("Amount") as a from {{ source('og_raw', 'ap_invoice') }} where "AfeId" is not null) i
where m.a <> i.a
