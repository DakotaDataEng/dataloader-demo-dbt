# DataLoader demo dbt projects

Twelve small dbt projects that run in DataLoader's demo environment. Four model a made-up retail business, one is a DuckLake test bed and seven model a made-up Texas oil and gas operator, one project per model family. Every row they read is generated fake data.

| Project | Folder | Reads | Builds | Runs |
|---|---|---|---|---|
| Sales | `sales/` | customers, products, orders, order lines | daily sales, order sales, region sales, customer lifetime value, customer segments (a view), recent orders and order events (incremental models) | when its loads finish (asset automation) |
| Operations | `operations/` | inventory, shipments, web events, sandbox orders, customers, order events and sensor readings | stock levels, late shipment rate, events per hour, sandbox daily orders, sandbox customer order totals, sandbox daily order events and sandbox sensor readings by device, day and quality | hourly |
| Finance | `finance/` | payments, plus the Sales models | daily revenue, daily margin | nightly, with a weekly full rebuild |
| Oil and gas | seven projects, see [Oil and gas model families](#oil-and-gas-model-families) | field capture, production accounting, land, accounting and reserves tables | volumes, LOS, capital, financial, revenue, land and reserves marts | nightly |
| Lakehouse | `lakehouse/` | the seven retail tables in a DuckLake's `bronze` schema | a cleaned silver copy of each, daily revenue by category, customer lifetime value, fulfilment time | when its loads finish (asset automation) |

Finance reads Sales' models as sources, so Lineage shows an edge from one project to another. Operations has a test that warns now and then on purpose.

## Targets and schemas

Each project uses the profile `dataloader` with two targets named `test` and `prod`, one thread each. DataLoader writes the profile at run time.

- Raw tables: `demo_raw_test` and `demo_raw_prod`, loaded by DataLoader with their source names (`customers`, `products`, `orders`, `order_lines`, `inventory`, `shipments`, `payments`, `web_events`).
- Oil and gas raw tables: `demo_og_raw_test` and `demo_og_raw_prod`. They keep the source's PascalCase column names, so the models quote them.
- Models: `demo_sales_<target>`, `demo_operations_<target>`, `demo_finance_<target>` and `demo_<project>_<target>` for each oil and gas project (`demo_oilgas_<target>`, `demo_oilgas_los_<target>` and so on).

The Postgres projects share one Postgres database. Sync Sales before Finance so Finance's sources resolve to Sales' models. Sync the oil and gas projects in the order volumes, land, revenue, LOS, capital, reserves, financial, so every project's sources resolve to models that already exist.

Lakehouse runs on a DuckLake destination, which DataLoader attaches as `lake`. Both targets read `lake.bronze`, loaded once by the PROD loads. Prod builds `silver` and `gold`; test builds `silver_test` and `gold_test`, so a test run never rebuilds prod's tables. Every model sets `+database: lake`: the profile's default database is in memory, and a model without it would be lost when the run ends.

## Runtime

The ten Postgres projects run on dbt-core 1.11 with dbt-postgres 1.10. DataLoader's bundled dbt does not build Postgres targets yet, so the demo registers a separate dbt-core runtime with DataLoader (`DL_DBT_EXECUTABLES`) and each project selects it.

Lakehouse runs on DataLoader's bundled dbt (dbt-oss 2.0.5 with DuckDB), so it needs no separate runtime. That dbt wants test arguments under `arguments:`, as its `schema.yml` files have them.

## Checks

- `sales/tests/verify_parse.py` parses Sales, Operations and Finance with both targets (six pairs) using the runtime above and checks each manifest has the shape DataLoader reads. Run it with this repository mounted read only at `/demo`.
- `oilgas/tests/verify_oilgas.py` parses the seven oil and gas projects with both targets. It checks that every model and column is described, that no test was silently disabled, and that every source one project reads from another matches a model that project builds (12 edges). With `--build --pg-port N` it also builds and tests every project with both targets against a disposable Postgres container loaded by `oilgas/tests/load_fixtures.py`. See [Running the oil and gas checks](#running-the-oil-and-gas-checks).
- `sales/tests/verify_sql.cjs <container>` runs every model in both schemas against a disposable Postgres container you own and checks 48 results (costs, statuses, dates across daylight saving, warning boundaries). It needs Node and Docker.

Each project's `tests/` folder also holds the dbt data tests that run with every build.

## Oil and gas model families

The oil and gas flavor is a Texas operator with field data capture, production accounting, land, a SCADA historian, an accounting system and a reserves export. Dakota's work in upstream oil and gas is a set of model families, so the demo has one dbt project for each. Every project has `staging` (views that rename columns), `intermediate` (views that join and shape) and `marts` (tables people read), tests, and a description on every model and column. Raw tables are in `demo_og_raw_<target>` with the source's PascalCase column names, so models quote them.

| Family | Folder | Marts | What it shows in a demo |
|---|---|---|---|
| Volumes | `oilgas/` | `fct_production`, `dim_well`, `fct_production_monthly`, `fct_allocation_variance` | Field volumes beside allocated volumes, and BOE per well per month. Every other family reads `fct_production_monthly`, so it is the hub of Lineage. |
| Land | `oilgas_land/` | `dim_owner`, `dim_lease`, `fct_lease_interest`, `fct_lease_production_monthly` | Leases, who owns what on each, and production per lease. Reads volumes. |
| Revenue | `oilgas_revenue/` | `fct_well_revenue_monthly`, `fct_owner_well_revenue_monthly`, `fct_owner_revenue_monthly` | Revenue per well at the Demo prices, revenue paid to each owner by well and month from the division orders, and owner revenue checked against what production accounting reported. Reads volumes and land. |
| LOS | `oilgas_los/` | `fct_los_monthly`, `fct_los_per_boe`, `fct_los_summary_monthly` | The lease operating statement by well, month and cost code, and LOS cost per BOE. Reads volumes. |
| Capital | `oilgas_capital/` | `fct_afe_variance`, `fct_afe_summary`, `fct_capital_spend_monthly` | AFE estimate against actual by cost code, which runs over and under. Reads accounting and land. |
| Reserves | `oilgas_reserves/` | `fct_reserves_by_category`, `fct_well_reserves`, `fct_reserves_vs_actuals`, `fct_reserves_run_change`, `fct_price_deck` | PDP, PDNP and PUD reserves and PV10 by report, the forecast held against what the wells produced, and how reserves moved between reports. Reads volumes. |
| Financial | `oilgas_financial/` | `fct_trial_balance`, `fct_jib_by_partner`, `fct_netback_monthly`, `fct_netback_by_field_monthly` | The ledger balancing, joint interest billing by partner, and operating netback per BOE after royalties. Reads revenue, LOS and volumes. |

The projects build into `demo_oilgas_<target>` (volumes) and `demo_oilgas_<family>_<target>` for the others. The existing `oilgas/` project is the volumes family under its old name, so its folder, project name and schema did not change.

### Where families read each other

A project reads another project's mart as a source, as Finance reads Sales, so Lineage crosses projects.

| Reader | Reads | From |
|---|---|---|
| land | `dim_well`, `fct_production_monthly` | volumes |
| revenue | `fct_production_monthly` | volumes |
| revenue | `dim_owner` | land |
| LOS | `fct_production_monthly` | volumes |
| capital | `dim_lease` | land |
| reserves | `dim_well`, `fct_production_monthly` | volumes |
| financial | `fct_production_monthly` | volumes |
| financial | `fct_well_revenue_monthly`, `fct_owner_well_revenue_monthly` | revenue |
| financial | `fct_los_per_boe` | LOS |

Capital's AFE variance reads the accounting tables (`afe`, `afe_line`, `ap_invoice`, `cost_code`) directly.

### A Lineage path from netback or reserves back to field data capture

Netback per BOE in `fct_netback_monthly` takes its BOE from the volumes project. Volumes builds BOE from the field's own measured volumes, which are the `daily_volume` table of the field data capture system. Read the path from the mart down to the raw table:

1. `demo_oilgas_financial.fct_netback_monthly` (financial)
2. source `volumes.fct_production_monthly`, which is the mart `demo_oilgas.fct_production_monthly` (volumes project)
3. `demo_oilgas.int_well_days`
4. `demo_oilgas.stg_daily_volumes`
5. source `og_raw.daily_volume`, the field data capture table `fdc.DailyVolume`

The same path starts from `demo_oilgas_reserves.fct_reserves_vs_actuals`: it reads source `volumes.fct_production_monthly` and continues at step 2. Netback also reads revenue (`fct_well_revenue_monthly`) and LOS (`fct_los_per_boe`), so its Lineage fans out to production accounting's allocations and the accounting system's invoices as well.

### Terms and definitions

- BOE (barrel of oil equivalent) is oil plus gas at 6 Mcf per barrel. The models compute it, the source does not store it. It uses allocated volumes unless a column says field.
- LOS (lease operating statement) cost lines are LOE, workover, production taxes and G&A. Production taxes are invoiced on the 1st of the month after the production they tax, so the LOS family places them in the production month. G&A has no well, so it appears only at the operator level.
- Netback is operating netback per well and month: gross (8/8ths) revenue less royalties, less production taxes, less LOE and workover. There is no transport in the data, and G&A is not in it. Netback per BOE is the same figure divided by allocated BOE, so it equals revenue per BOE less royalty per BOE less LOS per BOE. `gross_revenue` stays a column of `fct_netback_monthly`.
- Royalty is gross revenue times the sum of the division order decimal interests of the well's royalty owners. A royalty owner is an owner on the well's division order that no partner row points to through `partner.OwnerId`, so the working interest partners (the Demo's non-operating companies) are left out. The Demo seed names the royalty owners "Demo Mineral Owner".
- The Demo prices are $68.00 a barrel and $2.75 an Mcf. They are the dbt vars `demo_oil_price_usd_bbl` and `demo_gas_price_usd_mcf` in `oilgas_revenue/dbt_project.yml`, the same prices the source uses for tax invoices and monthly revenue.
- AFE variance is actual less estimate, so a positive variance is over the estimate. While an AFE is open, a negative variance includes spend not made yet.
- A well's lease comes from the `well_lease` table, never from the well number.
- Reserves volumes are gross, in thousand barrels (Mbbl) and million cubic feet (MMcf). Mboe is Mbbl plus MMcf divided by 6. PV10 is net to the operator.

### Running the oil and gas checks

The fixtures come from the Demo source's own SQL Server scripts, so the numbers are what a Demo shows. Use two disposable containers you own.

1. Start SQL Server (`mcr.microsoft.com/mssql/server:2022-CU14-ubuntu-22.04`) and Postgres 16, and run the source's `001-schema.sql` to `005-reserves.sql` through `sqlcmd` (the dataloader repository keeps them in `deploy/demo/oil-gas/mssql`).
2. Copy the tables into Postgres under `demo_og_raw_test` and `demo_og_raw_prod`:

   ```bash
   MSSQL_SA_PASSWORD=... PGPASSWORD=... uv run --python 3.12 --with pymssql --with 'psycopg[binary]' \
       python oilgas/tests/load_fixtures.py --mssql-port 5340 --pg-port 5341
   ```

3. Parse, build and test all seven projects with both targets:

   ```bash
   PGPASSWORD=... uv run --python 3.12 --with 'dbt-core==1.11.*' --with 'dbt-postgres==1.10.*' \
       python oilgas/tests/verify_oilgas.py --build --pg-port 5341
   ```

Each project's `tests/` folder holds reconciliation tests that run with every build:

- Volumes: monthly volumes add back to the daily rows.
- Land: each lease's interests add up to 1, and lease volumes add back to well volumes.
- Revenue: owner revenue equals what production accounting reported, owner by owner and month by month.
- LOS: LOS cost per well per month equals the AP invoices for it, and the operator total equals all LOS invoices.
- Capital: AFE variance equals actual less estimate, an AFE line's actual equals its capital invoices, and AFE totals add up from their lines.
- Reserves: EUR equals cumulative plus remaining, remaining equals the sum of the forecast months, and category totals add up to the well rows.
- Financial: the ledger balances overall and by journal, credits to accounts payable equal the AP invoices, debits to joint interest receivable equal the JIB bills, royalty cost equals the owner revenue the revenue project pays the royalty owners for the well and month within half a cent per royalty owner, and netback per BOE equals revenue less royalties less LOS less taxes per BOE, rebuilt from the raw invoices, allocations and division orders.
