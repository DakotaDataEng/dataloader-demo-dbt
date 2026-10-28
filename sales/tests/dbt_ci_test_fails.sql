-- dbt CI test: fails on purpose while any day has an order, to prove a failing test fails the pipeline job.
select sales_date, largest_order from {{ ref('daily_sales') }}
where largest_order >= 0
