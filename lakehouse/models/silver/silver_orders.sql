-- Latest row per order_id: the incremental load can land a key more than once.
select
    order_id,
    customer_id,
    ordered_at,
    status,
    channel,
    total_amount,
    created_at,
    updated_at,
    _dl_loaded_at as loaded_at
from {{ source('bronze', 'orders') }}
qualify row_number() over (
    partition by order_id
    order by updated_at desc, _dl_loaded_at desc
) = 1
