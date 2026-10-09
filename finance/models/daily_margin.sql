select
    s.sales_date as margin_date,
    s.merchandise_revenue,
    s.merchandise_cost,
    s.gross_margin,
    case when s.merchandise_revenue = 0 then null
         else s.gross_margin / s.merchandise_revenue end as margin_rate,
    r.collected_revenue
from {{ source('sales', 'daily_sales') }} s
join {{ ref('daily_revenue') }} r on r.revenue_date = s.sales_date
