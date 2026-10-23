-- One row per lease with its terms, its wells and the owners' interests. Capital reads it for lease names.
with wells as (
    select lease_id, count(*) as well_count
    from {{ ref('int_lease_wells') }}
    group by lease_id
), interests as (
    select lease_id, count(*) as owner_count, sum(decimal_interest) as total_decimal_interest
    from {{ ref('stg_lease_interests') }}
    group by lease_id
)
select
    l.lease_id,
    l.lease_name,
    l.county,
    l.acres,
    l.effective_date,
    l.expiry_date,
    coalesce(w.well_count, 0) as well_count,
    coalesce(i.owner_count, 0) as owner_count,
    coalesce(i.total_decimal_interest, 0) as total_decimal_interest
from {{ ref('stg_leases') }} as l
left join wells as w on w.lease_id = l.lease_id
left join interests as i on i.lease_id = l.lease_id
