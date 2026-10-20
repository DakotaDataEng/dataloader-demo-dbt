-- Latest row per payment_id: the incremental load can land a key more than once.
select
    payment_id,
    order_id,
    paid_at,
    method,
    status,
    amount,
    created_at,
    updated_at,
    _dl_loaded_at as loaded_at
from {{ source('bronze', 'payments') }}
qualify row_number() over (
    partition by payment_id
    order by updated_at desc, _dl_loaded_at desc
) = 1
