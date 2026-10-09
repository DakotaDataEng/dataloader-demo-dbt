"""Offline verification inside an existing DataLoader image, no packages needed.

Mount this repository read-only at /demo; run python3
/demo/sales/tests/verify_parse.py. All generated files stay in the container.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def main():
    root = Path('/demo')
    build = '--build' in sys.argv[1:]
    check_warn = '--check-warn' in sys.argv[1:]
    binary = Path('/opt/demo-dbt/bin/dbt')
    dbt_environment = dict(os.environ)
    dbt_environment.pop('DBT_ALLOW_EXPERIMENTAL_ADAPTERS', None)
    expected = {
        'sales': ({'order_sales', 'daily_sales', 'customer_lifetime_value'}, 8),
        'operations': ({'stock_levels', 'late_shipment_rate', 'events_hourly'}, 8),
        'finance': ({'daily_revenue', 'daily_margin'}, 5),
    }
    manifests = {}
    with tempfile.TemporaryDirectory(prefix='demo-dbt-') as temporary:
        work = Path(temporary)
        for environment in ('test', 'prod'):
            for project, (models, tests) in expected.items():
                output = work / environment / project
                output.mkdir(parents=True)
                (output / 'profiles.yml').write_text(
                    'dataloader:\n  target: ' + environment + '\n  outputs:\n'
                    '    ' + environment + ':\n      type: postgres\n' +
                    ('      host: host.docker.internal\n      port: 57220\n'
                     '      user: postgres\n      password: demo-verification-only\n' if build or check_warn else
                     '      host: localhost\n      port: 5432\n'
                     '      user: demo\n      password: parse-only\n') +
                    '      dbname: demo_warehouse\n'
                    '      schema: demo_' + project + '_' + environment + '\n'
                    '      threads: 1\n      sslmode: disable\n'
                )
                subprocess.run([
                    str(binary), 'parse', '--project-dir', str(root / project),
                    '--profiles-dir', str(output), '--profile', 'dataloader',
                    '--target', environment, '--target-path', str(output / 'target'),
                    '--log-path', str(output / 'logs'), '--no-partial-parse',
                    '--no-send-anonymous-usage-stats', '--no-version-check',
                ], check=True, env=dbt_environment)
                manifest = json.loads((output / 'target/manifest.json').read_text())
                assert manifest['metadata']['dbt_schema_version'].endswith('/manifest/v12.json')
                nodes = list(manifest['nodes'].values())
                assert {n['name'] for n in nodes if n['resource_type'] == 'model'} == models
                assert sum(n['resource_type'] == 'test' for n in nodes) == tests
                for node in nodes:
                    if node['resource_type'] == 'model':
                        assert node['schema'] == 'demo_' + project + '_' + environment
                        assert node['database'] == 'demo_warehouse'
                        assert node['config']['materialized'] == 'table'
                for source in manifest['sources'].values():
                    assert source['database'] == 'demo_warehouse'
                    schema = 'demo_sales_' if source['source_name'] == 'sales' else 'demo_raw_'
                    assert source['schema'] == schema + environment
                manifests[environment, project] = manifest
                print(f'PASS {project}/{environment}: {len(models)} models, {tests} tests', flush=True)
                if build:
                    subprocess.run([
                        str(binary), 'build', '--project-dir', str(root / project),
                        '--profiles-dir', str(output), '--profile', 'dataloader',
                        '--target', environment, '--target-path', str(output / 'target'),
                        '--log-path', str(output / 'logs'), '--no-send-anonymous-usage-stats',
                        '--no-version-check', '--vars', '{demo_incidents_enabled: false}',
                    ], check=True, env=dbt_environment)
                if check_warn and project == 'operations':
                    for enabled, status in ((True, 'warn'), (False, 'pass')):
                        subprocess.run([
                            str(binary), 'test', '--project-dir', str(root / project),
                            '--profiles-dir', str(output), '--profile', 'dataloader',
                            '--target', environment, '--target-path', str(output / 'target'),
                            '--log-path', str(output / 'logs'), '--no-send-anonymous-usage-stats',
                            '--no-version-check', '--select', 'demo_weekly_warning',
                            '--vars', json.dumps({'demo_incidents_enabled': enabled,
                                                  'demo_warning_at': '2026-10-07T20:07:00Z'}),
                        ], check=True, env=dbt_environment)
                        results = json.loads((output / 'target/run_results.json').read_text())['results']
                        assert len(results) == 1 and results[0]['status'] == status
                        print(f'PASS {environment}: scheduled incident {status}', flush=True)
        for environment in ('test', 'prod'):
            sales = manifests[environment, 'sales']
            finance = manifests[environment, 'finance']
            relations = {(n['database'], n['schema'], n['alias'])
                         for n in sales['nodes'].values() if n['resource_type'] == 'model'}
            for source in finance['sources'].values():
                if source['source_name'] == 'sales':
                    assert (source['database'], source['schema'], source['identifier']) in relations
            warning = next(n for n in manifests[environment, 'operations']['nodes'].values()
                           if n['name'] == 'demo_weekly_warning')
            assert warning['config']['severity'].lower() == 'warn', warning['config']
            assert warning['depends_on']['nodes'] == ['model.demo_operations.late_shipment_rate']
        print('PASS 6 manifest-v12 parses; 16 model instances; 42 test instances; both Lineage contracts; WARN severity')


if __name__ == '__main__':
    main()
