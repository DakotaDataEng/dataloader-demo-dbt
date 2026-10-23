-- Every lease's interests add up to 1, and the lease volumes add back to the well volumes they came from.
select lease_id::text as problem
from {{ ref('dim_lease') }}
where owner_count > 0 and total_decimal_interest <> 1
union all
select 'volumes'
from (
    select sum(allocated_boe) as lease_boe from {{ ref('fct_lease_production_monthly') }}
) l
cross join (
    select sum(allocated_boe) as well_boe from {{ source('volumes', 'fct_production_monthly') }}
) w
where l.lease_boe <> w.well_boe
