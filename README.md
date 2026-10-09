# Demo dbt projects

Three small Postgres projects use the same Demo warehouse destination and database. Each model is a table replaced at every build. There are no packages or new dependencies. Threads must be 1 on the internal VM.

## Git sync and targets

The lead and Jordan choose the sync source at deployment. Use this repository at a known merged ref with a vault held read only token when private, or a separate small read only repository. Preserve the relative project subfolders below or update each `project_subdir` deliberately. Use `sync_source: git` and set `git_ref`. Public access uses `git_credential: {kind: none}`. Never put credentials in the URL. Neither option creates a repository or credential through this work. Start with the [main README](../README.md).

Project subdirs and target configuration:

- Sales: `deploy/demo/dbt/sales`; TEST schema `demo_sales_test`, PROD schema `demo_sales_prod`.
- Operations: `deploy/demo/dbt/operations`; TEST schema `demo_operations_test`, PROD schema `demo_operations_prod`.
- Finance: `deploy/demo/dbt/finance`; TEST schema `demo_finance_test`, PROD schema `demo_finance_prod`.

For each target use `environment: test|prod`, `dbt_target: test|prod`, the same warehouse `destination_id`, and `target_config: {schema: <schema above>, threads: 1}`. Targets must be named exactly `test` and `prod`. Do not set model-level schema overrides: dbt's default schema concatenation would break the contract.

DataLoader generates a private `dataloader` profile from the destination. A checked-in `profiles.yml` is ignored. No additional source environment variables are required by these projects: the runtime clears the parent environment, so sources derive their database from `target.database` and schemas from `target.name`. Warehouse connection credentials belong in the destination and its existing secret configuration. Use manual Git sync or a conservative code-check interval such as 3600 seconds.

Use the isolated dbt-core Postgres runtime in [../dbt-runtime/README.md](../dbt-runtime/README.md). The existing image's bundled dbt needs an experimental Postgres opt-in and lacks its ADBC driver; this separate runtime supplies the supported Python adapter without changing the product or allowing runtime downloads. Mount its named volume read-only at `/opt/demo-dbt` and set server configuration `DL_DBT_EXECUTABLES=demo-postgres=/opt/demo-dbt/bin/dbt`, preserving any other entries separated by commas, semicolons or newlines. This is a `name=absolute-path` list, not JSON. Restart DataLoader once to register it, then confirm `GET /admin/dbt/health` lists `demo-postgres` with no version error. Set `dbt_executable: demo-postgres` for all three projects as an admin; the configuration script's input is `DEMO_DBT_EXECUTABLE=demo-postgres`.

Raw loads must write unprefixed table identifiers into `demo_raw_test` and `demo_raw_prod`: customers, products, orders, order_lines, inventory, shipments, payments, web_events. The instance's `test_dest_prefix` must already be empty: configuration preflight refuses a nonempty prefix and never changes that workspace setting automatically. Use uncapped TEST loads for the linked tables so foreign-key joins remain complete. New monthly nullable columns do not change models because queries select named fields.

## Bootstrap, automation and schedules

Configure, sync Sales, Operations then Finance, load every raw table in both environments, then build Sales, Operations and Finance in order. The main README describes the single deploy command and batch waits. Verify Finance's source mappings before activation. Projects start in dry run. Workspace TEST automation is off by the product's default, but the intended Demo runs live in both TEST and PROD. Enable workspace automation in both environments with dry run off as a deployment prerequisite. Readiness verifies this without changing global settings. Activation enables the Demo project live switches and lighter TEST schedules.

Sales default condition: `{"type":"on_upstream_updated","rate_limit_cron":"*/30 * * * *","timezone":"America/Edmonton","wait_for":"any"}`. The sources include order_lines as well as orders, customers and products, so changes to historical line cost and quantities rebuild the dependent models. Bootstrap must finish first; `wait_for: any` lets frequent orders trigger Sales without waiting for rarely changed dimensions. Builds coalesce into half-hour windows. Do not add an eager YAML condition to Operations or Finance; set their project default to `{"type":"manual"}` and use schedules.

All schedule time zones are `America/Edmonton`. PROD has:

- Operations hourly: `7 * * * *`, selector `tag:hourly`.
- Finance nightly: `30 2 * * *`, selector `tag:nightly`.
- Finance weekly full replacement: `30 3 * * 0`, selector `tag:weekly_full_refresh`.

TEST has Operations daily at `7 5 * * *` with `tag:hourly` and Finance daily at `30 6 * * *` with `tag:nightly`. Sales automation also runs in TEST, fed by hourly orders and daily other raw tables. The promotion candidate stays paused. New schedules start inactive until activation.

The schedule API accepts selectors, with no explicit `full_refresh` field. These finance table models fully replace their contents both nightly and weekly, meeting the demo full rebuild intent. To show an explicit full-refresh run, use `POST /assets/materialize` with Finance model asset IDs, `env`, and `full_refresh: true`; do not put `--full-refresh` in a schedule selector. Selector previews should contain 3 Operations models and 2 Finance models.

## Cross-project Lineage

Sales outputs `order_sales`, `daily_sales`, and `customer_lifetime_value`. Finance declares dbt sources `sales.order_sales` and `sales.daily_sales`, never cross-project `ref()` calls. Their manifest database is the warehouse dbname, their schema is `demo_sales_<target>`, and their identifiers exactly match Sales model aliases. DataLoader keys also include the destination ID, so both projects must use the same destination row. Finance revenue reads both Sales relations plus raw payments; margin reads daily Sales and Finance revenue. Sync Sales first so Finance sources map by exact relation to Sales model assets instead of external placeholders. Re-sync Finance if it was synced before Sales. Confirm the two source mappings report `method: relation` and `asset_kind: dbt_model`.

Finance runs on Postgres today by the lead's decision. DuckDB is currently a test-only dbt target in DataLoader and cannot be registered in the product. Move Finance to DuckDB once supported, with an explicit plan for accessing the Sales relations and preserving their Lineage mappings. No DuckDB destination registration is assumed here.

## Reporting and incidents

Sales excludes cancelled orders; merchandise margin uses historical order-line cost, not current product cost. Customer lifetime value includes zero-order customers. Totals cover all generated history once raw loads catch up. The generator never prunes rows. At one order and twelve events per 300 seconds, the eight source tables grow from 105,750 to 1,945,350 rows after 365 days. Raw incremental history therefore needs no manual reconciliation. Nightly FULL configs write separate snapshots. Finance counts only `settled` payments of non-cancelled orders, grouping collections by payment date and booked revenue by order date. It does not net refunds. Operations includes inactive products and overdue shipments. Business dates use Edmonton. Event buckets use UTC and keep repeated daylight-saving hours distinct. See the main README for reset and the Sunday load warning's current visibility limits.

`demo_weekly_warning` is a WARN-severity test on late shipment reporting every Wednesday from 14:00 inclusive to 15:00 exclusive Edmonton. The hourly 14:07 build reliably reports it, including an empty shipment table. This reporting incident is independent of the source Tuesday failure and Sunday dip. It never blocks downstream models. To disable it, set `demo_incidents_enabled: false` in the Operations project vars and sync the updated Git ref. For deterministic verification, supply `demo_warning_at` as a dbt `--vars` timestamp; omit it during normal runs.

## Verification

The projects define 21 dbt tests: Sales 8, Operations 8, Finance 5, including primary-key checks, aggregate reconciliation and numeric bounds. Build against loaded raw tables to execute them. A normal build outside the Wednesday window should pass all tests; inside it only `demo_weekly_warning` should WARN.

Offline parse and relation checks use the pre-existing DataLoader image, with no image build or pull and no network. From the repo root, mount only this worktree's `deploy/demo/dbt` read-only at `/demo` and run `python3.12 /demo/sales/tests/verify_parse.py` as the entrypoint. For example:

```text
docker run --rm --pull never --network none --name dl-demo-dbt-<job-id> --mount type=volume,source=<owned-runtime-volume>,target=/opt/demo-dbt,readonly --mount type=bind,source=<absolute-worktree>/deploy/demo/dbt,target=/demo,readonly --entrypoint python3.12 <existing-dataloader-image> /demo/sales/tests/verify_parse.py
```

The script uses only Python's standard library inside the image. It invokes the same registered dbt-core executable, generates disposable parse-only profiles in the container, runs all 3 projects in both targets, checks manifest v12 compatibility, model and test counts, exact source/model relations, table materialization and warning severity. Without `--build` it never connects to a database.

`node deploy/demo/dbt/sales/tests/verify_sql.cjs dl-test-pg-<job-id>` uses Node's standard library and Docker to execute all 8 models in both schemas on an owned disposable Postgres. It needs an empty `demo_warehouse` database and a `postgres` role inside that container. It uses `docker exec`, so no host port is needed by the harness. This fix round used its owned server on port 57230 and created those fixtures beside the source test database. The harness substitutes relation expressions and checks 40 results for historical costs, zero-order customers, payment statuses and dates, UTC daylight-saving buckets, overdue shipments and warning boundaries. It also executes the three reconciliation and bounds tests. Remove the owned container and volume afterwards. This proves SQL semantics. Adapter materialization remains a separate runtime check.

The original dbt worker's optional adapter check uses `verify_parse.py --build` with synthetic fixtures on `host.docker.internal:57220` and incidents disabled. It builds in dependency order. That profile is fixed to the original fixture port and credentials; adapt it to your own assigned test endpoint before a new connected run. Never point it at another worker's database. Connected checks omit `--network none` without using host networking. Mount only your owned runtime volume read only. The fix round did not rerun adapter builds or install a runtime. The original bundled-runtime build failed at its missing ADBC driver, so the dbt worker used the separate runtime.

`verify_parse.py --check-warn` checks actual dbt results during the engineered window and with incidents disabled in both environments. The original dbt worker reported six manifest-v12 parses, six builds, 40 SQL assertions, four incident-result checks and two runtime setup checks. This fix round reran all 40 SQL assertions successfully against its own server. It did not rerun Python parse, adapter build or runtime setup checks. Deployment and in-instance sync and automation remain the lead's work.
