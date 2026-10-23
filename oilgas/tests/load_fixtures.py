"""Copy the oil and gas Demo source tables from a SQL Server container into a Postgres container.

The copy mimics what DataLoader lands: one schema per target (demo_og_raw_test and demo_og_raw_prod), snake case
table names, and the source's PascalCase column names. The fixtures come from the Demo source's own seed (and any
generator ticks you ran), so the numbers are the ones a Demo shows. Synthetic data only.

Run it against disposable containers you own:

    MSSQL_SA_PASSWORD=... PGPASSWORD=... uv run --python 3.12 --with pymssql --with 'psycopg[binary]' \
        python oilgas/tests/load_fixtures.py --mssql-port 5340 --pg-port 5341

The historian's readings (one million rows) are not copied: no model reads them.
"""
import argparse
import os

import psycopg
import pymssql

# (database, schema, source table, warehouse table). Revenue and run tickets are read from their data tables,
# because the views in front of them raise the planted faults.
TABLES = [
    ('DemoFieldCapture', 'fdc', 'Well', 'well'),
    ('DemoFieldCapture', 'fdc', 'DailyVolume', 'daily_volume'),
    ('DemoProductionAccounting', 'pa', 'DailyAllocation', 'daily_allocation'),
    ('DemoProductionAccounting', 'pa', 'DivisionOrder', 'division_order'),
    ('DemoProductionAccounting', 'pa', 'MonthlyRevenueData', 'monthly_revenue'),
    ('DemoProductionAccounting', 'pa', 'RunTicketData', 'run_ticket'),
    ('DemoLand', 'land', 'Owner', 'owner'),
    ('DemoLand', 'land', 'Lease', 'lease'),
    ('DemoLand', 'land', 'LeaseInterest', 'lease_interest'),
    ('DemoHistorian', 'hist', 'Tag', 'tag'),
    ('DemoAccounting', 'acct', 'Account', 'account'),
    ('DemoAccounting', 'acct', 'CostCode', 'cost_code'),
    ('DemoAccounting', 'acct', 'Vendor', 'vendor'),
    ('DemoAccounting', 'acct', 'WellLease', 'well_lease'),
    ('DemoAccounting', 'acct', 'Partner', 'partner'),
    ('DemoAccounting', 'acct', 'WellInterest', 'well_interest'),
    ('DemoAccounting', 'acct', 'Afe', 'afe'),
    ('DemoAccounting', 'acct', 'AfeLine', 'afe_line'),
    ('DemoAccounting', 'acct', 'ApInvoice', 'ap_invoice'),
    ('DemoAccounting', 'acct', 'GlEntry', 'gl_entry'),
    ('DemoAccounting', 'acct', 'JibBilling', 'jib_billing'),
    ('DemoReserves', 'res', 'ReserveRun', 'reserve_run'),
    ('DemoReserves', 'res', 'PriceDeck', 'price_deck'),
    ('DemoReserves', 'res', 'WellReserve', 'well_reserve'),
    ('DemoReserves', 'res', 'ForecastMonth', 'forecast_month'),
]

SIMPLE = {
    'int': 'integer', 'bigint': 'bigint', 'smallint': 'smallint', 'tinyint': 'smallint', 'bit': 'boolean',
    'float': 'double precision', 'real': 'real', 'date': 'date', 'varchar': 'text', 'nvarchar': 'text',
    'char': 'text', 'nchar': 'text',
}


def pg_type(row):
    name = row['DATA_TYPE']
    if name in ('decimal', 'numeric'):
        return f"numeric({row['NUMERIC_PRECISION']},{row['NUMERIC_SCALE']})"
    if name in ('datetime2', 'datetime', 'smalldatetime'):
        return 'timestamp'
    return SIMPLE[name]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--mssql-host', default='127.0.0.1')
    parser.add_argument('--mssql-port', type=int, required=True)
    parser.add_argument('--pg-host', default='127.0.0.1')
    parser.add_argument('--pg-port', type=int, required=True)
    parser.add_argument('--pg-db', default='demo_warehouse')
    parser.add_argument('--pg-user', default='postgres')
    parser.add_argument('--targets', default='test,prod')
    args = parser.parse_args()
    targets = args.targets.split(',')

    ms = pymssql.connect(args.mssql_host, 'sa', os.environ['MSSQL_SA_PASSWORD'], port=args.mssql_port, as_dict=True)
    pg = psycopg.connect(host=args.pg_host, port=args.pg_port, dbname=args.pg_db, user=args.pg_user,
                         password=os.environ['PGPASSWORD'], autocommit=True)
    cursor = ms.cursor()
    total = 0
    for target in targets:
        pg.execute(f'drop schema if exists demo_og_raw_{target} cascade')
        pg.execute(f'create schema demo_og_raw_{target}')
    for database, schema, source, dest in TABLES:
        cursor.execute(
            f'select COLUMN_NAME, DATA_TYPE, NUMERIC_PRECISION, NUMERIC_SCALE from {database}.INFORMATION_SCHEMA.COLUMNS '
            'where TABLE_SCHEMA = %s and TABLE_NAME = %s order by ORDINAL_POSITION', (schema, source))
        columns = cursor.fetchall()
        assert columns, f'{database}.{schema}.{source} has no columns'
        names = [c['COLUMN_NAME'] for c in columns]
        quoted = ', '.join('"' + n + '"' for n in names)
        cursor.execute(f'select {quoted} from {database}.{schema}.{source}')
        rows = [tuple(r[n] for n in names) for r in cursor.fetchall()]
        ddl = ', '.join('"' + c['COLUMN_NAME'] + '" ' + pg_type(c) for c in columns)
        for target in targets:
            table = f'demo_og_raw_{target}.{dest}'
            pg.execute(f'create table {table} ({ddl})')
            with pg.cursor() as copy_cursor:
                with copy_cursor.copy(f'copy {table} ({quoted}) from stdin') as copy:
                    for row in rows:
                        copy.write_row(row)
        print(f'{dest}: {len(rows)} rows')
        total += len(rows)
    print(f'loaded {len(TABLES)} tables, {total} rows into {len(targets)} schemas')


if __name__ == '__main__':
    main()
