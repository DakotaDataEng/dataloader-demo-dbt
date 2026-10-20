-- Latest row per inventory_id: the incremental load can land a key more than once.
select
    inventory_id,
    product_id,
    location,
    on_hand,
    reorder_level,
    created_at,
    updated_at,
    _dl_loaded_at as loaded_at
from {{ source('bronze', 'inventory') }}
qualify row_number() over (
    partition by inventory_id
    order by updated_at desc, _dl_loaded_at desc
) = 1
