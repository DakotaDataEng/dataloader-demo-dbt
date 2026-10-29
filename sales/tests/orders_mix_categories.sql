-- Every order should hold products from at least two categories.
select order_id, category_count
from {{ ref('order_sales') }}
where category_count < 2
