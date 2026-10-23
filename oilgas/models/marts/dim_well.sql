-- One row per well, with its first and last production day and the days it produced.
select
    w.well_id,
    w.api_number,
    w.well_name,
    w.operator,
    w.field,
    w.spud_date,
    w.status,
    min(d.production_date) as first_production_date,
    max(d.production_date) as last_production_date,
    count(d.production_date) as producing_days
from {{ ref('stg_wells') }} as w
left join {{ ref('int_well_days') }} as d
    on d.well_id = w.well_id
group by w.well_id, w.api_number, w.well_name, w.operator, w.field, w.spud_date, w.status
