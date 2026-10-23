-- LOS cost per well per month equals the AP invoices for it. Taxes are invoiced on the 1st of the following month, so a tax invoice counts toward the month before.
-- Every LOS invoice must also land in the statement: nothing dropped, nothing counted twice.
with invoices as (
    select
        i."WellId" as well_id,
        case when c."Category" = 'Tax' then cast(date_trunc('month', i."InvoiceDate") - interval '1 month' as date)
             else cast(date_trunc('month', i."InvoiceDate") as date) end as los_month,
        sum(i."Amount") as amount
    from {{ source('og_raw', 'ap_invoice') }} as i
    join {{ source('og_raw', 'cost_code') }} as c on c."CostCode" = i."CostCode"
    where c."Category" in ('LOE', 'Workover', 'Tax') and i."WellId" is not null
    group by 1, 2
), statement as (
    select well_id, los_month, sum(amount) as amount
    from {{ ref('fct_los_monthly') }}
    where well_id is not null
    group by 1, 2
), per_boe as (
    select well_id, los_month, total_los_cost
    from {{ ref('fct_los_per_boe') }}
)
select coalesce(i.well_id, s.well_id)::text as problem
from invoices as i
full join statement as s on s.well_id = i.well_id and s.los_month = i.los_month
where i.amount is distinct from s.amount
union all
select p.well_id::text
from per_boe as p
left join statement as s on s.well_id = p.well_id and s.los_month = p.los_month
where p.total_los_cost <> coalesce(s.amount, 0)
union all
select 'all invoices'
from (select sum(total_los_cost) as t from {{ ref('fct_los_summary_monthly') }}) a
cross join (
    select sum(i."Amount") as t
    from {{ source('og_raw', 'ap_invoice') }} i
    join {{ source('og_raw', 'cost_code') }} c on c."CostCode" = i."CostCode"
    where c."Category" in ('LOE', 'Workover', 'Tax', 'G&A')
) b
where a.t <> b.t
