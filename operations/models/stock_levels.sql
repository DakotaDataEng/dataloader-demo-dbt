select
    i.inventory_id,
    i.product_id,
    p.sku,
    p.demo_name,
    p.category,
    i.location,
    i.on_hand,
    i.reorder_level,
    i.on_hand < i.reorder_level as needs_reorder,
    i.on_hand * p.unit_cost as stock_value
from {{ source('demo_raw', 'inventory') }} i
join {{ source('demo_raw', 'products') }} p on p.product_id = i.product_id
