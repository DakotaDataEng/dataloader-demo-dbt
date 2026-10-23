-- Netback per BOE equals revenue less royalties less LOS less taxes, per BOE, for every well and month.
-- The figures are rebuilt here from the raw invoices (production taxes belong to the month before their invoice date),
-- the raw allocations and the raw division orders, with revenue from the revenue project, so the check does not reuse the LOS or volumes marts.
with costs as (
    select
        i."WellId" as well_id,
        case when c."Category" = 'Tax' then cast(date_trunc('month', i."InvoiceDate") - interval '1 month' as date)
             else cast(date_trunc('month', i."InvoiceDate") as date) end as month,
        sum(i."Amount") filter (where c."Category" in ('LOE', 'Workover')) as operating_cost,
        sum(i."Amount") filter (where c."Category" = 'Tax') as taxes
    from {{ source('og_raw', 'ap_invoice') }} as i
    join {{ source('og_raw', 'cost_code') }} as c on c."CostCode" = i."CostCode"
    where i."WellId" is not null and c."Category" in ('LOE', 'Workover', 'Tax')
    group by 1, 2
), boe as (
    select
        "WellId" as well_id,
        cast(date_trunc('month', "ProductionDate") as date) as month,
        sum("AllocatedOilBbl" + "AllocatedGasMcf" / 6.0) as boe
    from {{ source('og_raw', 'daily_allocation') }}
    group by 1, 2
), royalty as (
    select d."WellId" as well_id, sum(d."DecimalInterest") as royalty_decimal
    from {{ source('og_raw', 'division_order') }} as d
    where d."OwnerId" not in (select "OwnerId" from {{ source('og_raw', 'partner') }} where "OwnerId" is not null)
    group by 1
), expected as (
    select
        b.well_id,
        b.month,
        (r.gross_revenue - round(r.gross_revenue * coalesce(y.royalty_decimal, 0), 2) - coalesce(c.operating_cost, 0) - coalesce(c.taxes, 0)) / b.boe as netback_per_boe
    from boe as b
    join {{ source('revenue', 'fct_well_revenue_monthly') }} as r on r.well_id = b.well_id and r.production_month = b.month
    left join costs as c on c.well_id = b.well_id and c.month = b.month
    left join royalty as y on y.well_id = b.well_id
)
select n.well_id::text || ' ' || n.production_month::text as problem
from {{ ref('fct_netback_monthly') }} as n
left join expected as e on e.well_id = n.well_id and e.month = n.production_month
where e.netback_per_boe is null
   or abs(n.netback_per_boe - e.netback_per_boe) > 0.000001
   or abs(n.netback_per_boe - (n.revenue_per_boe - n.royalty_per_boe - n.los_per_boe)) > 0.000001
