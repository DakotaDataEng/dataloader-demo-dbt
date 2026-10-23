-- One row per well with the lease it sits on and the lease's terms.
select
    wl.well_id,
    w.well_name,
    w.field,
    wl.lease_id,
    l.lease_name,
    l.county,
    l.acres,
    l.effective_date,
    l.expiry_date,
    wl.cost_center
from {{ ref('stg_well_leases') }} as wl
join {{ ref('stg_leases') }} as l
    on l.lease_id = wl.lease_id
left join {{ source('volumes', 'dim_well') }} as w
    on w.well_id = wl.well_id
