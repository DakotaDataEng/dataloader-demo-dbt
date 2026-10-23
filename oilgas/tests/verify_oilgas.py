"""Check the seven oil and gas projects: parse with both targets, and optionally build and test them.

Parse (no database needed):

    python oilgas/tests/verify_oilgas.py --dbt /opt/demo-dbt/bin/dbt

Build (against a disposable Postgres container you own, loaded by oilgas/tests/load_fixtures.py):

    python oilgas/tests/verify_oilgas.py --dbt /opt/demo-dbt/bin/dbt --build --pg-port 5341

It needs dbt-core 1.11 with dbt-postgres 1.10, the runtime the README describes, and nothing else.
Everything it writes goes to a temporary folder.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]

# In sync order: a project only reads projects before it.
PROJECTS = {
    'oilgas': {
        'schema': 'oilgas',
        'models': {'stg_wells', 'stg_daily_volumes', 'stg_allocations', 'int_well_days', 'fct_production', 'dim_well',
                   'fct_production_monthly', 'fct_allocation_variance'},
        'reads': {},
    },
    'oilgas_land': {
        'schema': 'oilgas_land',
        'models': {'stg_leases', 'stg_lease_interests', 'stg_owners', 'stg_well_leases', 'int_lease_wells', 'dim_owner',
                   'dim_lease', 'fct_lease_interest', 'fct_lease_production_monthly'},
        'reads': {'volumes': 'oilgas'},
    },
    'oilgas_revenue': {
        'schema': 'oilgas_revenue',
        'models': {'stg_division_orders', 'stg_monthly_revenue', 'int_well_month_value', 'int_owner_well_month',
                   'fct_well_revenue_monthly', 'fct_owner_well_revenue_monthly', 'fct_owner_revenue_monthly'},
        'reads': {'volumes': 'oilgas', 'land': 'oilgas_land'},
    },
    'oilgas_los': {
        'schema': 'oilgas_los',
        'models': {'stg_ap_invoices', 'stg_cost_codes', 'stg_vendors', 'int_los_lines', 'fct_los_monthly',
                   'fct_los_per_boe', 'fct_los_summary_monthly'},
        'reads': {'volumes': 'oilgas'},
    },
    'oilgas_capital': {
        'schema': 'oilgas_capital',
        'models': {'stg_afes', 'stg_afe_lines', 'stg_capital_invoices', 'stg_capital_cost_codes', 'int_afe_line_invoices',
                   'int_afe_lines', 'fct_afe_variance', 'fct_afe_summary', 'fct_capital_spend_monthly'},
        'reads': {'land': 'oilgas_land'},
    },
    'oilgas_reserves': {
        'schema': 'oilgas_reserves',
        'models': {'stg_reserve_runs', 'stg_price_decks', 'stg_well_reserves', 'stg_forecast_months', 'int_reserve_rows',
                   'int_forecast_boe', 'fct_well_reserves', 'fct_reserves_by_category', 'fct_reserves_vs_actuals',
                   'fct_reserves_run_change', 'fct_price_deck'},
        'reads': {'volumes': 'oilgas'},
    },
    'oilgas_financial': {
        'schema': 'oilgas_financial',
        'models': {'stg_accounts', 'stg_gl_entries', 'stg_partners', 'stg_jib_billings', 'stg_division_orders', 'int_gl_lines', 'int_journals',
                   'int_well_royalty_interest',
                   'fct_trial_balance', 'fct_jib_by_partner', 'fct_netback_monthly', 'fct_netback_by_field_monthly'},
        'reads': {'volumes': 'oilgas', 'revenue': 'oilgas_revenue', 'los': 'oilgas_los'},
    },
}


def schema_for(project, environment):
    return f'demo_{PROJECTS[project]["schema"]}_{environment}'


def run_dbt(dbt, command, project, environment, profiles, work, extra=()):
    output = work / environment / project
    subprocess.run(
        [dbt, *command.split(), '--project-dir', str(ROOT / project), '--profiles-dir', str(profiles / environment / project),
         '--profile', 'dataloader', '--target', environment, '--target-path', str(output / 'target'),
         '--log-path', str(output / 'logs'), '--no-send-anonymous-usage-stats', '--no-version-check', *extra],
        check=True, env={k: v for k, v in os.environ.items() if k != 'DBT_ALLOW_EXPERIMENTAL_ADAPTERS'},
        stdout=subprocess.DEVNULL)
    return output / 'target'


def write_profile(profiles, project, environment, host, port, password):
    folder = profiles / environment / project
    folder.mkdir(parents=True)
    (folder / 'profiles.yml').write_text(
        'dataloader:\n  target: ' + environment + '\n  outputs:\n'
        '    ' + environment + ':\n      type: postgres\n'
        f'      host: {host}\n      port: {port}\n      user: postgres\n      password: {password}\n'
        '      dbname: demo_warehouse\n'
        '      schema: ' + schema_for(project, environment) + '\n'
        '      threads: 1\n      sslmode: disable\n')


def check_parse(manifest, project, environment):
    spec = PROJECTS[project]
    assert not manifest['disabled'], (project, 'a test or model was disabled, usually by a source that is not declared', list(manifest['disabled']))
    nodes = manifest['nodes'].values()
    models = {n['name']: n for n in nodes if n['resource_type'] == 'model'}
    assert set(models) == spec['models'], (project, set(models) ^ spec['models'])
    tests = sum(n['resource_type'] == 'test' for n in nodes)
    assert tests > 0
    for name, node in models.items():
        assert node['schema'] == schema_for(project, environment), (project, name, node['schema'])
        assert node['database'] == 'demo_warehouse'
        assert node['description'].strip(), f'{project}.{name} has no description'
        assert node['description'].rstrip().endswith('Synthetic Demo data.'), f'{project}.{name} lacks the Demo label'
        layer = name.split('_')[0]
        expected_materialization = 'table' if layer in ('fct', 'dim') else 'view'
        assert node['config']['materialized'] == expected_materialization, (project, name)
        assert node['columns'], f'{project}.{name} documents no columns'
        for column in node['columns'].values():
            assert column['description'].strip(), f'{project}.{name}.{column["name"]} has no description'
        for text in (node['description'], *(c['description'] for c in node['columns'].values())):
            assert chr(0x2014) not in text and chr(0x2013) not in text and '#3278' not in text
    return len(models), tests


def check_sources(manifests, environment):
    """Every source one project reads from another matches a model that project builds, so Lineage crosses projects."""
    edges = 0
    for project, spec in PROJECTS.items():
        manifest = manifests[environment, project]
        sources = {s['source_name']: s for s in manifest['sources'].values()}
        for source in manifest['sources'].values():
            assert source['database'] == 'demo_warehouse'
            if source['source_name'] == 'og_raw':
                assert source['schema'] == f'demo_og_raw_{environment}'
                continue
            producer = spec['reads'][source['source_name']]
            assert source['schema'] == schema_for(producer, environment), (project, source['source_name'], source['schema'])
            built = {(n['database'], n['schema'], n['alias'])
                     for n in manifests[environment, producer]['nodes'].values() if n['resource_type'] == 'model'}
            assert (source['database'], source['schema'], source['identifier']) in built, \
                f'{project} reads {source["identifier"]} which {producer} does not build'
            edges += 1
        assert set(spec['reads']) <= set(sources), (project, 'declared a read it does not source')
    return edges


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dbt', default='dbt')
    parser.add_argument('--build', action='store_true')
    parser.add_argument('--pg-host', default='127.0.0.1')
    parser.add_argument('--pg-port', type=int, default=5432)
    parser.add_argument('--pg-password', default=os.environ.get('PGPASSWORD', 'parse-only'))
    args = parser.parse_args()
    manifests = {}
    with tempfile.TemporaryDirectory(prefix='demo-og-dbt-') as temporary:
        work = Path(temporary) / 'work'
        profiles = Path(temporary) / 'profiles'
        for environment in ('test', 'prod'):
            for project in PROJECTS:
                write_profile(profiles, project, environment, args.pg_host, args.pg_port, args.pg_password)
                target = run_dbt(args.dbt, 'parse', project, environment, profiles, work, ['--no-partial-parse'])
                manifest = json.loads((target / 'manifest.json').read_text())
                assert manifest['metadata']['dbt_schema_version'].endswith('/manifest/v12.json')
                manifests[environment, project] = manifest
                models, tests = check_parse(manifest, project, environment)
                print(f'PASS parse {project}/{environment}: {models} models, {tests} tests', flush=True)
        for environment in ('test', 'prod'):
            print(f'PASS {environment}: {check_sources(manifests, environment)} cross-project source edges match a built model', flush=True)
        if args.build:
            totals = {}
            for environment in ('test', 'prod'):
                for project in PROJECTS:
                    target = run_dbt(args.dbt, 'build', project, environment, profiles, work)
                    results = json.loads((target / 'run_results.json').read_text())['results']
                    statuses = {}
                    for result in results:
                        statuses[result['status']] = statuses.get(result['status'], 0) + 1
                    assert set(statuses) <= {'success', 'pass'}, (project, environment, statuses)
                    totals[environment, project] = statuses
                    print(f'PASS build {project}/{environment}: {statuses.get("success", 0)} models built, '
                          f'{statuses.get("pass", 0)} tests passed', flush=True)
                    # Every column a model builds is described, so Lineage shows a description for it.
                    target = run_dbt(args.dbt, 'docs generate', project, environment, profiles, work)
                    catalog = json.loads((target / 'catalog.json').read_text())
                    manifest = manifests[environment, project]
                    for unique_id, node in manifest['nodes'].items():
                        if node['resource_type'] != 'model':
                            continue
                        built = {c.lower() for c in catalog['nodes'][unique_id]['columns']}
                        documented = {c.lower() for c in node['columns']}
                        assert built == documented, (project, node['name'], built ^ documented)
            print('PASS build: every project builds and passes its tests with both targets')


if __name__ == '__main__':
    main()
