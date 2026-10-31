{% set summary = source('python_jobs', 'well_test_summary') %}
select
    current_timestamp as refreshed_at,
    'Rebuilt after the Python job Well test summary finished' as note
