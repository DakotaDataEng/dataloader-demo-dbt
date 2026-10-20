{#- Prod builds into the custom schema names verbatim (silver, gold). Any other
    target appends its name (silver_test, gold_test), so a test run never
    rebuilds prod's tables: both targets read the same bronze. A model with no
    custom schema builds into the target schema. -#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- elif target.name == 'prod' -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ custom_schema_name | trim }}_{{ target.name }}
    {%- endif -%}
{%- endmacro %}
