-- One row per owner, with how many leases the owner holds an interest in. Revenue reads it for owner names.
select
    o.owner_id,
    o.owner_name,
    o.owner_type,
    count(distinct li.lease_id) as lease_count
from {{ ref('stg_owners') }} as o
left join {{ ref('stg_lease_interests') }} as li
    on li.owner_id = o.owner_id
group by o.owner_id, o.owner_name, o.owner_type
