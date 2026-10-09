# DataLoader demo dbt projects

Three small dbt projects that run in DataLoader's demo environment. They model a made-up retail business; every row they read is generated fake data.

| Project | Folder | Reads | Builds | Runs |
|---|---|---|---|---|
| Sales | `sales/` | customers, products, orders, order lines | daily sales, order sales, customer lifetime value | when its loads finish (asset automation) |
| Operations | `operations/` | inventory, shipments, web events | stock levels, late shipment rate, events per hour | hourly |
| Finance | `finance/` | payments, plus the Sales models | daily revenue, daily margin | nightly, with a weekly full rebuild |

Finance reads Sales' models as sources, so Lineage shows an edge from one project to another. Operations has a test that warns now and then on purpose.

## Targets and schemas

Each project uses the profile `dataloader` with two targets named `test` and `prod`, one thread each. DataLoader writes the profile at run time.

- Raw tables: `demo_raw_test` and `demo_raw_prod`, loaded by DataLoader with their source names (`customers`, `products`, `orders`, `order_lines`, `inventory`, `shipments`, `payments`, `web_events`).
- Models: `demo_sales_<target>`, `demo_operations_<target>` and `demo_finance_<target>`.

All three share one Postgres database. Sync Sales before Finance so Finance's sources resolve to Sales' models.

## Runtime

The projects run on dbt-core 1.11 with dbt-postgres 1.10. DataLoader's bundled dbt does not build Postgres targets yet, so the demo registers a separate dbt-core runtime with DataLoader (`DL_DBT_EXECUTABLES`) and each project selects it.

## Checks

- `sales/tests/verify_parse.py` parses all six project and target pairs with the runtime above and checks each manifest has the shape DataLoader reads. Run it with this repository mounted read only at `/demo`.
- `sales/tests/verify_sql.cjs <container>` runs every model in both schemas against a disposable Postgres container you own and checks 40 results (costs, statuses, dates across daylight saving, warning boundaries). It needs Node and Docker.

Each project's `tests/` folder also holds the dbt data tests that run with every build.
