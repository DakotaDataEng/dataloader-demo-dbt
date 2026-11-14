-- Latest row per order_line_id: the incremental load can land a key more than once.
-- depends_on: {{ ref('silver_orders') }}
select
    order_line_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    unit_cost,
    line_amount,
    created_at,
    updated_at,
    _dl_loaded_at as loaded_at
from {{ source('bronze', 'order_lines') }}
qualify row_number() over (
    partition by order_line_id
    order by updated_at desc, _dl_loaded_at desc
) = 1
