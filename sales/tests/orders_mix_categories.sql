-- An average order in every province and channel should hold products from at least two categories.
select region, channel, average_categories
from {{ ref('region_sales') }}
where average_categories < 2
