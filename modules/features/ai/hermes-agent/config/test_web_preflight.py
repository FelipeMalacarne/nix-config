"""Run generated proxy preflight with explicit stub CLI/HTTP fixtures.

This tests guard logic without configuring the live Tailscale daemon.
"""
import json
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import unittest
from urllib.parse import urlsplit

MANIFEST = json.loads(Path(sys.argv.pop(1)).read_text())


class ProxyPreflight(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='hermes-preflight-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.cli = self.root / 'tailscale'
        self.curl = self.root / 'curl'
        self.cli.write_text('#!' + sys.executable + '\n' + '''
import json, pathlib, sys
fixture = json.loads(pathlib.Path(sys.argv[0] + '.json').read_text())
if fixture.get('exit_code'):
    sys.exit(fixture['exit_code'])
if sys.argv[1:] == ['status', '--json']:
    print(json.dumps(fixture['status']))
elif sys.argv[1:] == ['serve', 'status', '--json']:
    print(json.dumps(fixture['routes']))
else:
    sys.exit(99)  # The preflight may inspect, never change daemon state.
''')
        self.curl.write_text('#!' + sys.executable + '\n' + '''
import json, pathlib, sys
fixture = json.loads(pathlib.Path(sys.argv[0] + '.json').read_text())
if fixture.get('exit_code'):
    sys.exit(fixture['exit_code'])
if sys.argv[1:] != fixture['args']:
    print('unexpected curl arguments: ' + repr(sys.argv[1:]), file=sys.stderr)
    sys.exit(98)
print(json.dumps(fixture['body']))
''')
        self.cli.chmod(0o700)
        self.curl.chmod(0o700)
        origin = urlsplit(MANIFEST['publicUrl'])
        self.port = str(origin.port or 443)
        self.target = origin.hostname + ':' + self.port
        web_argv = shlex.split(MANIFEST['web']['ExecStart'][0])
        web_port = web_argv[web_argv.index('--port') + 1]
        self.backend_url = 'http://127.0.0.1:' + web_port + '/api/status'
        self.host_header = 'Host: ' + origin.netloc
        self.status = {'BackendState': 'Running', 'Self': {'DNSName': origin.hostname + '.'}}
        self.auth = {'auth_required': True, 'auth_providers': ['basic']}
        self.script = MANIFEST['preStart'].replace(MANIFEST['tailscale'], str(self.cli))
        self.script = self.script.replace(MANIFEST['curl'], str(self.curl))

    def run_preflight(self, *, status=None, routes=None, auth=None, cli_exit=0, http_exit=0,
                      script=None):
        Path(str(self.cli) + '.json').write_text(json.dumps({
            'status': self.status if status is None else status,
            'routes': {} if routes is None else routes, 'exit_code': cli_exit,
        }))
        Path(str(self.curl) + '.json').write_text(json.dumps({
            'body': self.auth if auth is None else auth,
            'exit_code': http_exit,
            'args': [
                '--fail', '--silent', '--show-error', '--max-time', '10',
                '--header', self.host_header, self.backend_url,
            ],
        }))
        result = subprocess.run([MANIFEST['bash'], '-c', script or self.script],
                                capture_output=True, text=True)
        return result.returncode

    def test_ready_authenticated_dashboard_is_allowed(self):
        self.assertEqual(self.run_preflight(), 0)

    def test_absent_funnel_permission_is_allowed(self):
        self.assertEqual(self.run_preflight(routes={'AllowFunnel': {}}), 0)

    def test_disabled_funnel_permission_is_allowed(self):
        for routes in (
            {'AllowFunnel': {self.target: False}},
            {'Foreground': {'previous-owner': {'AllowFunnel': {self.target: False}}}},
        ):
            with self.subTest(routes=routes):
                self.assertEqual(self.run_preflight(routes=routes), 0)

    def test_other_funnel_targets_are_preserved(self):
        other = '8443' if self.port == '443' else '443'
        routes = {
            'AllowFunnel': {urlsplit(MANIFEST['publicUrl']).hostname + ':' + other: True},
            'Foreground': {
                'other-owner': {'AllowFunnel': {'other.example.ts.net:' + self.port: True}},
            },
        }
        self.assertEqual(self.run_preflight(routes=routes), 0)

    def test_other_https_port_is_preserved(self):
        other = '8443' if self.port == '443' else '443'
        self.assertEqual(self.run_preflight(routes={'TCP': {other: {'HTTPS': True}}}), 0)

    def test_existing_target_port_is_not_replaced(self):
        for routes in (
            {'TCP': {self.port: {'HTTPS': True}}},
            {'Foreground': {'other-owner': {'TCP': {self.port: {'HTTPS': True}}}}},
        ):
            with self.subTest(routes=routes):
                self.assertNotEqual(self.run_preflight(routes=routes), 0)

    def test_top_level_stale_funnel_permission_is_rejected(self):
        self.assertNotEqual(self.run_preflight(routes={
            'AllowFunnel': {self.target: True},
        }), 0)

    def test_foreground_stale_funnel_permission_is_rejected(self):
        self.assertNotEqual(self.run_preflight(routes={
            'Foreground': {'previous-owner': {'AllowFunnel': {self.target: True}}},
        }), 0)

    def test_wrong_backend_url_is_rejected_by_http_fixture(self):
        script = self.script.replace(self.backend_url, 'http://127.0.0.1:1/api/status')
        self.assertNotEqual(self.run_preflight(script=script), 0)

    def test_wrong_host_header_is_rejected_by_http_fixture(self):
        script = self.script.replace(self.host_header, 'Host: unrelated.invalid')
        self.assertNotEqual(self.run_preflight(script=script), 0)

    def test_wrong_tailnet_hostname_is_rejected(self):
        self.assertNotEqual(self.run_preflight(status={
            'BackendState': 'Running', 'Self': {'DNSName': 'different.example.ts.net.'},
        }), 0)

    def test_not_logged_in_is_rejected(self):
        self.assertNotEqual(self.run_preflight(status=self.status | {'BackendState': 'NeedsLogin'}), 0)

    def test_disabled_auth_gate_is_rejected(self):
        self.assertNotEqual(self.run_preflight(auth=self.auth | {'auth_required': False}), 0)

    def test_missing_auth_provider_is_rejected(self):
        self.assertNotEqual(self.run_preflight(auth=self.auth | {'auth_providers': []}), 0)

    def test_daemon_failure_is_not_masked_by_pipeline(self):
        self.assertNotEqual(self.run_preflight(cli_exit=1), 0)

    def test_http_failure_is_not_masked_by_pipeline(self):
        self.assertNotEqual(self.run_preflight(http_exit=22), 0)


if __name__ == '__main__':
    unittest.main(verbosity=2)
