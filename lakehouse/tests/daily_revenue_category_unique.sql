select sales_date, category, count(*) as rows_for_key
from {{ ref('daily_revenue_by_category') }}
group by sales_date, category
having count(*) > 1
