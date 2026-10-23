-- The lease operating statement: cost per well, month and LOS line (cost code). G&A has no well, so its rows have no well_id.
select
    md5(coalesce(well_id::text, 'none') || '|' || cast(los_month as text) || '|' || cost_code) as los_key,
    well_id,
    los_month,
    cost_code,
    los_line,
    category,
    count(*) as invoice_count,
    sum(amount) as amount
from {{ ref('int_los_lines') }}
group by well_id, los_month, cost_code, los_line, category
