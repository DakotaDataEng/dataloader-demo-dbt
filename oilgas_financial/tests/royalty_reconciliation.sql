-- Royalty cost equals the owner revenue the revenue project pays the royalty owners, for the well and month.
-- Royalty owners are the owners on a well's division order that no partner row points to. Every well and month is checked.
-- Rounding sets the allowed difference: half a cent per royalty owner on the well and month.
-- The revenue project rounds each owner's revenue once, so the sum for n owners can differ from the royalty by at most 0.005 times n.
with royalty_owners as (
    select o.owner_id, o.well_id, o.production_month, o.total_revenue
    from {{ source('revenue', 'fct_owner_well_revenue_monthly') }} as o
    where o.owner_id not in (select "OwnerId" from {{ source('og_raw', 'partner') }} where "OwnerId" is not null)
), paid as (
    select well_id, production_month, sum(total_revenue) as paid, count(*) as owner_count
    from royalty_owners
    group by well_id, production_month
)
select n.well_id::text || ' ' || n.production_month::text as problem
from {{ ref('fct_netback_monthly') }} as n
left join paid as p on p.well_id = n.well_id and p.production_month = n.production_month
where abs(n.royalty_cost - coalesce(p.paid, 0)) > 0.005 * coalesce(p.owner_count, 0)
