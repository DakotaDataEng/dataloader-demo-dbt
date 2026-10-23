-- What the operator billed each non-operating partner per cost month: gross cost, billed amount and the share billed.
select
    md5(cast(j.partner_id as text) || '|' || cast(j.billing_month as text)) as jib_key,
    j.partner_id,
    p.partner_name,
    j.billing_month,
    max(j.billing_date) as billing_date,
    count(distinct j.well_id) as well_count,
    sum(j.gross_cost) as gross_cost,
    sum(j.billed_amount) as billed_amount,
    case when sum(j.gross_cost) = 0 then null else sum(j.billed_amount) / sum(j.gross_cost) end as billed_share
from {{ ref('stg_jib_billings') }} as j
join {{ ref('stg_partners') }} as p
    on p.partner_id = j.partner_id
group by j.partner_id, p.partner_name, j.billing_month
