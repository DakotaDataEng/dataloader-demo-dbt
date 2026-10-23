-- One row per lease and owner: the owner's decimal interest in the lease.
select
    li.lease_interest_id,
    li.lease_id,
    l.lease_name,
    li.owner_id,
    o.owner_name,
    o.owner_type,
    li.decimal_interest
from {{ ref('stg_lease_interests') }} as li
join {{ ref('stg_leases') }} as l on l.lease_id = li.lease_id
join {{ ref('stg_owners') }} as o on o.owner_id = li.owner_id
