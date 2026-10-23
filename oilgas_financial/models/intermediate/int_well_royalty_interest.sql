-- The share of each well's revenue that goes to royalty owners: the sum of the division order decimals of owners who are not working interest partners.
-- A working interest partner is an owner that a partner row points to through partner.OwnerId. Every other owner on the division order is a royalty owner.
select
    d.well_id,
    count(*) as royalty_owner_count,
    sum(d.decimal_interest) as royalty_decimal
from {{ ref('stg_division_orders') }} as d
where d.owner_id not in (
    select owner_id from {{ ref('stg_partners') }} where owner_id is not null
)
group by d.well_id
