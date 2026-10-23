-- Royalty cost equals the owner revenue the revenue project pays the royalty owners, for the well and month, within a cent.
-- Royalty owners are the owners on a well's division order that no partner row points to. Every well and month with revenue is checked.
with royalty_owners as (
    select o.owner_id, o.well_id, o.production_month, o.total_revenue
    from {{ source('revenue', 'fct_owner_well_revenue_monthly') }} as o
    where o.owner_id not in (select "OwnerId" from {{ source('og_raw', 'partner') }} where "OwnerId" is not null)
), paid as (
    select well_id, production_month, sum(total_revenue) as paid
    from royalty_owners
    group by well_id, production_month
)
select n.well_id::text || ' ' || n.production_month::text as problem
from {{ ref('fct_netback_monthly') }} as n
left join paid as p on p.well_id = n.well_id and p.production_month = n.production_month
where abs(n.royalty_cost - coalesce(p.paid, 0)) > 0.01
