-- Latest row per customer_id: the incremental load can land a key more than once.
select
    customer_id,
    demo_name as customer_name,
    email,
    region,
    created_at,
    updated_at,
    _dl_loaded_at as loaded_at
from {{ source('bronze', 'customers') }}
qualify row_number() over (
    partition by customer_id
    order by updated_at desc, _dl_loaded_at desc
) = 1
