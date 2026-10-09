{{ config(severity='warn', tags=['demo_incident']) }}
-- An intentional reporting warning every Wednesday 14:00-15:00 Edmonton.
-- The aggregate returns one row even with no shipments, keeping it predictable.
with observed as (
    select coalesce(cast(nullif('{{ var("demo_warning_at", "") }}', '') as timestamptz), current_timestamp)
        at time zone 'America/Edmonton' as local_time
)
select 'Demo scheduled reporting warning' as reason, count(*) as reporting_rows
from {{ ref('late_shipment_rate') }}
having {{ 'true' if var('demo_incidents_enabled', true) else 'false' }} and exists (
    select 1 from observed
    where extract(isodow from local_time) = 3 and extract(hour from local_time) = 14
)
