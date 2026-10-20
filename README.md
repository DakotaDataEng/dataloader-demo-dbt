# DataLoader demo dbt projects

Five small dbt projects that run in DataLoader's demo environment. Four model a made-up retail business and one a made-up oil and gas operator; every row they read is generated fake data.

| Project | Folder | Reads | Builds | Runs |
|---|---|---|---|---|
| Sales | `sales/` | customers, products, orders, order lines | daily sales, order sales, customer lifetime value | when its loads finish (asset automation) |
| Operations | `operations/` | inventory, shipments, web events, sandbox orders, customers, order events and sensor readings | stock levels, late shipment rate, events per hour, sandbox daily orders, sandbox customer order totals, sandbox daily order events and sandbox sensor readings by device, day and quality | hourly |
| Finance | `finance/` | payments, plus the Sales models | daily revenue, daily margin | nightly, with a weekly full rebuild |
| Oil and gas | `oilgas/` | wells, daily allocations | staged allocations, production per well per day | nightly |
| Lakehouse | `lakehouse/` | the seven retail tables in a DuckLake's `bronze` schema | a cleaned silver copy of each, daily revenue by category, customer lifetime value, fulfilment time | when its loads finish (asset automation) |

Finance reads Sales' models as sources, so Lineage shows an edge from one project to another. Operations has a test that warns now and then on purpose.

## Targets and schemas

Each project uses the profile `dataloader` with two targets named `test` and `prod`, one thread each. DataLoader writes the profile at run time.

- Raw tables: `demo_raw_test` and `demo_raw_prod`, loaded by DataLoader with their source names (`customers`, `products`, `orders`, `order_lines`, `inventory`, `shipments`, `payments`, `web_events`).
- Oil and gas raw tables: `demo_og_raw_test` and `demo_og_raw_prod`. They keep the source's PascalCase column names, so the models quote them.
- Models: `demo_sales_<target>`, `demo_operations_<target>`, `demo_finance_<target>` and `demo_oilgas_<target>`.

The first four share one Postgres database. Sync Sales before Finance so Finance's sources resolve to Sales' models.

Lakehouse runs on a DuckLake destination, which DataLoader attaches as `lake`. Both targets read `lake.bronze`, loaded once by the PROD loads. Prod builds `silver` and `gold`; test builds `silver_test` and `gold_test`, so a test run never rebuilds prod's tables. Every model sets `+database: lake`: the profile's default database is in memory, and a model without it would be lost when the run ends.

## Runtime

The four Postgres projects run on dbt-core 1.11 with dbt-postgres 1.10. DataLoader's bundled dbt does not build Postgres targets yet, so the demo registers a separate dbt-core runtime with DataLoader (`DL_DBT_EXECUTABLES`) and each project selects it.

Lakehouse runs on DataLoader's bundled dbt (dbt-oss 2.0.5 with DuckDB), so it needs no separate runtime. That dbt wants test arguments under `arguments:`, as its `schema.yml` files have them.

## Checks

- `sales/tests/verify_parse.py` parses Sales, Operations and Finance with both targets (six pairs) using the runtime above and checks each manifest has the shape DataLoader reads. Run it with this repository mounted read only at `/demo`.
- `sales/tests/verify_sql.cjs <container>` runs every model in both schemas against a disposable Postgres container you own and checks 40 results (costs, statuses, dates across daylight saving, warning boundaries). It needs Node and Docker.

Each project's `tests/` folder also holds the dbt data tests that run with every build.
