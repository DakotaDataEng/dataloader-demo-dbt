-- Latest row per shipment_id: the incremental load can land a key more than once.
select
    shipment_id,
    order_id,
    carrier,
    status,
    shipped_at,
    expected_delivery_at,
    delivered_at,
    created_at,
    updated_at,
    _dl_loaded_at as loaded_at
from {{ source('bronze', 'shipments') }}
qualify row_number() over (
    partition by shipment_id
    order by updated_at desc, _dl_loaded_at desc
) = 1
