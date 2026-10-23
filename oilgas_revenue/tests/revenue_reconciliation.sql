-- Owner revenue built here equals what production accounting reported, owner by owner and month by month.
-- Every owner paid revenue must also have a reported row, and the owners' shares of a well never exceed the well's gross revenue.
select owner_id::text as problem
from {{ ref('fct_owner_revenue_monthly') }}
where reported_total_revenue is null or abs(difference) > 0.01
union all
select 'owners paid more than the wells earned'
from (
    select sum(total_revenue) as paid from {{ ref('fct_owner_revenue_monthly') }}
) o
cross join (
    select sum(gross_revenue) as earned from {{ ref('fct_well_revenue_monthly') }}
) w
where o.paid > w.earned + 1
