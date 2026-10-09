// Run against ONLY the worker's own disposable Postgres container.
// No npm packages. This checks SQL semantics, not dbt materialization.
const { readFileSync } = require('node:fs');
const { join, resolve } = require('node:path');
const { execFileSync } = require('node:child_process');
const assert = require('node:assert/strict');
const container = process.argv[2];
assert.match(container || '', /^dl-test-pg-j[0-9]+-[0-9]+-[a-z0-9]+$/);
const root = resolve(__dirname, '../..');
let checks = 0;
function sql(statement) {
  return execFileSync('docker', ['exec', '-i', container, 'psql', '-X', '-qAt',
    '-v', 'ON_ERROR_STOP=1', '-U', 'postgres', '-d', 'demo_warehouse'],
    { input: statement, encoding: 'utf8' }).trim();
}
function check(statement, expected) {
  assert.equal(sql(statement), expected, statement);
  checks++;
}
function render(project, path, environment, at = '', enabled = true) {
  return readFileSync(join(root, project, path), 'utf8')
    .replace(/\{\{\s*config\([\s\S]*?\)\s*\}\}/g, '')
    .replace(/\{\{\s*source\('([^']+)',\s*'([^']+)'\)\s*\}\}/g,
      (_, source, table) => `${source === 'sales' ? 'demo_sales' : 'demo_raw'}_${environment}.${table}`)
    .replace(/\{\{\s*ref\('([^']+)'\)\s*\}\}/g, (_, table) => `demo_${project}_${environment}.${table}`)
    .replace(/\{\{ var\("demo_warning_at", ""\) \}\}/g, at)
    .replace(/\{\{ 'true' if var\('demo_incidents_enabled', true\) else 'false' \}\}/g, String(enabled));
}
for (const environment of ['test', 'prod']) {
  const raw = `demo_raw_${environment}`;
  const sales = `demo_sales_${environment}`;
  const operations = `demo_operations_${environment}`;
  const finance = `demo_finance_${environment}`;
  sql(`create schema ${raw}; create schema ${sales}; create schema ${operations}; create schema ${finance};
    create table ${raw}.customers(customer_id bigint primary key, demo_name text, region text);
    insert into ${raw}.customers values (1,'Demo customer 1','West'),(2,'Demo customer 2','East');
    create table ${raw}.products(product_id bigint primary key, sku text, demo_name text, category text, unit_cost numeric(12,2));
    insert into ${raw}.products values (1,'DEMO-1','Demo product 1','Demo goods',99);
    create table ${raw}.orders(order_id bigint primary key,customer_id bigint,ordered_at timestamptz,status text,channel text,total_amount numeric(12,2));
    insert into ${raw}.orders values (1,1,'2026-10-08T02:00:00Z','completed','web',20),
      (2,1,'2026-10-08T02:00:00Z','cancelled','web',100);
    create table ${raw}.order_lines(order_id bigint,product_id bigint,quantity integer,unit_cost numeric(12,2),line_amount numeric(12,2));
    insert into ${raw}.order_lines values (1,1,2,3,20),(2,1,1,3,100);
    create table ${raw}.inventory(inventory_id bigint primary key,product_id bigint,location text,on_hand integer,reorder_level integer);
    insert into ${raw}.inventory values (1,1,'Demo shelf',2,5);
    create table ${raw}.shipments(shipment_id bigint primary key,carrier text,expected_delivery_at timestamptz,status text,delivered_at timestamptz);
    insert into ${raw}.shipments values (1,'Demo carrier','2020-01-01Z','delivered','2020-01-02Z'),
      (2,'Demo carrier','2020-01-01Z','delivered','2019-12-31Z'),
      (3,'Demo carrier','2020-01-01Z','in_transit',null);
    create table ${raw}.web_events(event_at timestamptz,event_type text,session_id text,customer_id bigint);
    insert into ${raw}.web_events values ('2026-11-01T07:30:00Z','view','a',null),('2026-11-01T08:30:00Z','view','b',1);
    create table ${raw}.payments(order_id bigint,paid_at timestamptz,amount numeric(12,2),status text);
    insert into ${raw}.payments values (1,'2026-10-09T02:00:00Z',20,'settled'),
      (2,'2026-10-09T02:00:00Z',100,'refunded'),(1,'2026-10-09T02:00:00Z',15,'pending');`);
  const models = {
    sales: ['order_sales', 'daily_sales', 'customer_lifetime_value'],
    operations: ['stock_levels', 'late_shipment_rate', 'events_hourly'],
    finance: ['daily_revenue', 'daily_margin'],
  };
  for (const [project, names] of Object.entries(models)) {
    for (const name of names) {
      sql(`create table demo_${project}_${environment}.${name} as ${render(project, `models/${name}.sql`, environment)};`);
    }
  }
  check(`select count(*) from ${sales}.order_sales;`, '1');
  check(`select sales_date || '|' || gross_revenue || '|' || merchandise_cost || '|' || gross_margin from ${sales}.daily_sales;`, '2026-10-07|20.00|6.00|14.00');
  check(`select lifetime_revenue from ${sales}.customer_lifetime_value where customer_id=2;`, '0');
  check(`select needs_reorder from ${operations}.stock_levels;`, 't');
  check(`select shipment_count || '|' || late_count from ${operations}.late_shipment_rate;`, '3|2');
  check(`select count(*) from ${operations}.events_hourly;`, '2');
  check(`select sum(collected_revenue) from ${finance}.daily_revenue;`, '20.00');
  check(`select booked_revenue from ${finance}.daily_revenue where revenue_date='2026-10-08';`, '0');
  check(`select gross_margin from ${finance}.daily_margin;`, '14.00');
  for (const [project, name] of [['sales','sales_reconciliation'],['operations','operations_bounds'],['finance','margin_reconciliation']]) {
    check(render(project, `tests/${name}.sql`, environment), '');
  }
  function warning(at, enabled = true) {
    return `select count(*) from (${render('operations', 'tests/demo_weekly_warning.sql', environment, at, enabled)}) q;`;
  }
  check(warning('2026-10-07T19:59:59Z'), '0');
  check(warning('2026-10-07T20:00:00Z'), '1');
  check(warning('2026-10-07T20:59:59Z'), '1');
  check(warning('2026-10-07T21:00:00Z'), '0');
  check(warning('2026-10-07T20:07:00Z', false), '0');
  check(warning('2026-12-02T21:07:00Z'), '1');
  // Empty model still gives a predictable incident, and disabling stays off.
  sql(`truncate ${operations}.late_shipment_rate;`);
  check(warning('2026-10-07T20:07:00Z'), '1');
  check(warning('2026-10-07T20:07:00Z', false), '0');
  console.log(`PASS ${environment}: 8 model SQL statements and 20 result checks`);
}
console.log(`PASS ${checks} SQL result checks total`);
