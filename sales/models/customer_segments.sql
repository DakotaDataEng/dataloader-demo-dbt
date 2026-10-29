{{ config(materialized='view') }}
-- Each customer's spending band, from their revenue to date.
select
    customer_id,
    demo_name,
    region,
    lifetime_revenue,
    case
        when lifetime_revenue >= 5000 then 'high'
        when lifetime_revenue >= 1000 then 'medium'
        else 'low'
    end as segment
from {{ ref('customer_lifetime_value') }}
