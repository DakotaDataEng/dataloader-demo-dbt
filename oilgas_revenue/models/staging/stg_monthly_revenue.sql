-- The owner revenue production accounting reports each month, with snake case names.
select
    "MonthlyRevenueId" as monthly_revenue_id,
    "OwnerId" as owner_id,
    cast("RevenueMonth" as date) as revenue_month,
    "OilRevenue" as oil_revenue,
    "GasRevenue" as gas_revenue,
    "TotalRevenue" as total_revenue,
    "ModifiedDate" as modified_at
from {{ source('og_raw', 'monthly_revenue') }}
