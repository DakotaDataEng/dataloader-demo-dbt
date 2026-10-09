select margin_date from {{ ref('daily_margin') }}
where gross_margin <> merchandise_revenue - merchandise_cost
