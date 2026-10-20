-- Latest row per product_id: the incremental load can land a key more than once.
select
    product_id,
    sku,
    demo_name as product_name,
    category,
    unit_price,
    unit_cost,
    is_active,
    created_at,
    updated_at,
    _dl_loaded_at as loaded_at
from {{ source('bronze', 'products') }}
qualify row_number() over (
    partition by product_id
    order by updated_at desc, _dl_loaded_at desc
) = 1
