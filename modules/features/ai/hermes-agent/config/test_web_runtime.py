"""Exercise generated Hermes services with disposable state and loopback sockets.

No live credentials, tailnet changes, browser sessions, or model requests.
"""
import base64
import hashlib
import http.client
from http.cookies import SimpleCookie
import json
import os
from pathlib import Path
import secrets
import shlex
import signal
import socket
import subprocess
import sys
import tempfile
import time
import unittest
from urllib.parse import urlsplit

from websockets.exceptions import InvalidStatus
from websockets.sync.client import connect

MANIFEST = json.loads(Path(sys.argv.pop(1)).read_text())


def free_port():
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        return sock.getsockname()[1]


def stop(process):
    if process.poll() is None:
        os.killpg(process.pid, signal.SIGTERM)
        try:
            process.wait(timeout=15)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)


class WebRuntime(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix='hermes-web-check-')
        cls.addClassCleanup(cls.tmp.cleanup)
        cls.root = Path(cls.tmp.name)
        cls.home = cls.root / 'state'
        cls.home.mkdir(mode=0o700)
        # Managed Hermes requires the skeleton that Home Manager creates.
        for directory in MANIFEST['stateDirectories']:
            (cls.home / directory).mkdir(parents=True, exist_ok=True, mode=0o700)
        cls.original_env = 'EXISTING_PROVIDER_MARKER=preserved\n'
        (cls.home / '.env').write_text(cls.original_env)
        (cls.home / 'config.yaml').write_text(json.dumps({
            'model': {'default': 'fixture-model', 'provider': 'openai'},
            'terminal': {'cwd': str(cls.root)},
        }))
        cls.private_token = secrets.token_hex(32)
        cls.token_file = cls.home / '.backend-session-token'
        cls.token_file.write_text(cls.private_token + '\n')
        cls.token_file.chmod(0o600)
        cls.password = secrets.token_urlsafe(32)
        salt = secrets.token_bytes(16)
        digest = hashlib.scrypt(cls.password.encode(), salt=salt, n=16384, r=8, p=1, dklen=32)
        cls.web_credentials = {
            'HERMES_DASHBOARD_BASIC_AUTH_PASSWORD_HASH':
                'scrypt$16384$8$1$' + base64.b64encode(salt).decode() + '$' + base64.b64encode(digest).decode(),
            'HERMES_DASHBOARD_BASIC_AUTH_SECRET': secrets.token_hex(32),
        }
        cls.private_port = free_port()
        cls.web_port = free_port()
        cls.private_env = cls.environment(MANIFEST['private'])
        cls.web_env = cls.environment(MANIFEST['web']) | cls.web_credentials
        cls.public_url = cls.web_env['HERMES_DASHBOARD_PUBLIC_URL']
        cls.authority = urlsplit(cls.public_url).netloc
        cls.username = cls.web_env['HERMES_DASHBOARD_BASIC_AUTH_USERNAME']
        # Relocate only fixture paths and ports in the real upstream launcher.
        launcher = Path(MANIFEST['private']['ExecStart'][0]).read_text()
        launcher = launcher.replace(MANIFEST['tokenFile'], str(cls.token_file))
        launcher = launcher.replace('--port ' + str(MANIFEST['privatePort']), '--port ' + str(cls.private_port))
        cls.private_launcher = cls.root / 'private-launcher'
        cls.private_launcher.write_text(launcher)
        cls.private_launcher.chmod(0o700)
        cls.private_process = cls.start([str(cls.private_launcher)], cls.private_env, 'private')
        cls.wait_ready(cls.private_process, cls.private_port)
        cls.web_argv = shlex.split(MANIFEST['web']['ExecStart'][0])
        cls.web_argv[cls.web_argv.index('--port') + 1] = str(cls.web_port)
        cls.web_process = cls.start(cls.web_argv, cls.web_env, 'web')
        cls.wait_ready(cls.web_process, cls.web_port)

    @classmethod
    def environment(cls, service):
        # Never inherit the invoking agent's credentials or runtime selectors.
        env = {k: os.environ[k] for k in ('PATH', 'LANG', 'TZ') if k in os.environ}
        env.update(dict(item.split('=', 1) for item in service['Environment']))
        for key in service.get('UnsetEnvironment', []):
            env.pop(key, None)
        env.update(HOME=str(cls.root), HERMES_HOME=str(cls.home))
        return env

    @classmethod
    def start(cls, argv, env, name):
        log = (cls.root / (name + '.log')).open('w+')
        cls.addClassCleanup(log.close)
        process = subprocess.Popen(argv, env=env, cwd=cls.root, stdin=subprocess.DEVNULL,
                                   stdout=log, stderr=subprocess.STDOUT, start_new_session=True)
        cls.addClassCleanup(stop, process)
        return process

    @classmethod
    def wait_ready(cls, process, port):
        deadline = time.monotonic() + 100
        while time.monotonic() < deadline:
            if process.poll() is not None:
                raise AssertionError('Fixture dashboard exited before readiness')
            try:
                status, _, _ = cls.request(port, '/api/status')
                if status == 200:
                    return
            except (OSError, http.client.HTTPException):
                pass
            time.sleep(0.2)
        raise AssertionError('Fixture dashboard did not become ready within 100 seconds')

    @classmethod
    def request(cls, port, path, *, method='GET', body=None, headers=None):
        conn = http.client.HTTPConnection('127.0.0.1', port, timeout=15)
        try:
            data = None if body is None else json.dumps(body)
            actual_headers = {'Content-Type': 'application/json'}
            if port == cls.web_port:
                actual_headers.update({
                    'Host': cls.authority,
                    'X-Forwarded-Proto': 'https',
                    'X-Forwarded-For': '100.64.0.10',
                    'Origin': cls.public_url,
                })
            actual_headers.update(headers or {})
            conn.request(method, path, body=data, headers=actual_headers)
            response = conn.getresponse()
            return response.status, response.getheaders(), response.read()
        finally:
            conn.close()

    def login(self):
        status, headers, body = self.request(self.web_port, '/auth/password-login', method='POST', body={
            'provider': 'basic', 'username': self.username, 'password': self.password,
        })
        self.assertEqual(status, 200)
        self.assertTrue(json.loads(body)['ok'])
        cookies = SimpleCookie()
        for key, value in headers:
            if key.lower() == 'set-cookie':
                cookies.load(value)
        self.assertTrue(any(c['secure'] and c['httponly'] for c in cookies.values()))
        return '; '.join(name + '=' + cookie.value for name, cookie in cookies.items())

    def ticket(self, cookie):
        status, _, body = self.request(self.web_port, '/api/auth/ws-ticket', method='POST',
                                      body={}, headers={'Cookie': cookie})
        self.assertEqual(status, 200)
        return json.loads(body)['ticket']

    def websocket(self, port, query, *, origin=None):
        sock = socket.create_connection(('127.0.0.1', port), timeout=15)
        authority = self.authority if port == self.web_port else '127.0.0.1:' + str(port)
        headers = {'X-Forwarded-Proto': 'https', 'X-Forwarded-For': '100.64.0.10'} if port == self.web_port else {}
        try:
            return connect('ws://' + authority + '/api/ws?' + query, sock=sock,
                           origin=origin or (self.public_url if port == self.web_port else 'http://' + authority),
                           additional_headers=headers, open_timeout=20, close_timeout=2)
        except BaseException:
            sock.close()
            raise

    def test_private_desktop_token_and_websocket_still_work(self):
        status, _, body = self.request(self.private_port, '/api/status')
        self.assertEqual(status, 200)
        self.assertFalse(json.loads(body)['auth_required'])
        status, _, _ = self.request(self.private_port, '/api/config',
                                    headers={'Authorization': 'Bearer ' + self.private_token})
        self.assertEqual(status, 200)
        with self.websocket(self.private_port, 'token=' + self.private_token) as ws:
            self.assertIn('gateway.ready', ws.recv(timeout=20))

    def test_web_requires_login_and_rejects_private_token(self):
        status, _, body = self.request(self.web_port, '/api/status')
        self.assertEqual(status, 200)
        self.assertTrue(json.loads(body)['auth_required'])
        self.assertIn('basic', json.loads(body)['auth_providers'])
        for headers in ({}, {'Authorization': 'Bearer ' + self.private_token}):
            status, _, _ = self.request(self.web_port, '/api/config', headers=headers)
            self.assertEqual(status, 401)
        status, headers, _ = self.request(self.web_port, '/')
        self.assertIn(status, (302, 303, 307))
        self.assertIn('/login', dict(headers)['location'])
        with self.assertRaises(InvalidStatus) as rejection:
            self.websocket(self.web_port, 'token=' + self.private_token)
        self.assertEqual(rejection.exception.response.status_code, 403)

    def test_wrong_password_is_rejected(self):
        status, _, _ = self.request(self.web_port, '/auth/password-login', method='POST', body={
            'provider': 'basic', 'username': self.username, 'password': 'incorrect-fixture-value',
        })
        self.assertEqual(status, 401)

    def test_login_https_cookies_shared_config_and_ticket_websocket(self):
        cookie = self.login()
        status, _, body = self.request(self.web_port, '/api/auth/me', headers={'Cookie': cookie})
        self.assertEqual(status, 200)
        self.assertEqual(json.loads(body)['provider'], 'basic')
        status, _, body = self.request(self.web_port, '/api/config', headers={'Cookie': cookie})
        self.assertEqual(status, 200)
        self.assertIn(str(self.root), body.decode())
        ticket = self.ticket(cookie)
        with self.websocket(self.web_port, 'ticket=' + ticket) as ws:
            self.assertIn('gateway.ready', ws.recv(timeout=20))
        with self.assertRaises(InvalidStatus) as rejection:
            self.websocket(self.web_port, 'ticket=' + ticket)
        self.assertEqual(rejection.exception.response.status_code, 403)
        self.assertEqual((self.home / '.env').read_text(), self.original_env)
        self.assertTrue(self.token_file.read_text().strip() == self.private_token)

    def test_unrelated_host_and_origin_are_rejected(self):
        cookie = self.login()
        status, _, _ = self.request(self.web_port, '/api/config', headers={
            'Cookie': cookie, 'Host': 'unrelated.invalid',
        })
        self.assertEqual(status, 400)
        with self.assertRaises(InvalidStatus) as rejection:
            self.websocket(self.web_port, 'ticket=' + self.ticket(cookie), origin='https://unrelated.invalid')
        self.assertEqual(rejection.exception.response.status_code, 403)

    def test_services_ignore_a_sticky_active_profile(self):
        sticky = self.home / 'active_profile'
        sticky.write_text('missing-profile-fixture\n')
        processes = []
        try:
            private_port = free_port()
            candidate_launcher = self.root / 'private-profile-check'
            candidate_launcher.write_text(self.private_launcher.read_text().replace(
                '--port ' + str(self.private_port), '--port ' + str(private_port)))
            candidate_launcher.chmod(0o700)
            private = self.start([str(candidate_launcher)], self.private_env, 'private-profile-check')
            processes.append(private)
            self.wait_ready(private, private_port)
            web_port = free_port()
            argv = list(self.web_argv)
            argv[argv.index('--port') + 1] = str(web_port)
            web = self.start(argv, self.web_env, 'web-profile-check')
            processes.append(web)
            self.wait_ready(web, web_port)
            self.assertEqual(sticky.read_text(), 'missing-profile-fixture\n')
            self.assertFalse((self.home / 'profiles' / 'missing-profile-fixture').exists())
        finally:
            sticky.unlink()
            for process in processes:
                stop(process)

    def test_web_fails_closed_without_credentials(self):
        env = {k: v for k, v in self.web_env.items() if k not in self.web_credentials}
        argv = list(self.web_argv)
        argv[argv.index('--port') + 1] = str(free_port())
        process = self.start(argv, env, 'no-credentials')
        self.assertNotEqual(process.wait(timeout=45), 0)

    def test_login_survives_web_restart(self):
        cookie = self.login()
        stop(self.web_process)
        type(self).web_process = self.start(self.web_argv, self.web_env, 'web-restarted')
        self.wait_ready(self.web_process, self.web_port)
        status, _, _ = self.request(self.web_port, '/api/auth/me', headers={'Cookie': cookie})
        self.assertEqual(status, 200)
        self.assertIsNone(self.private_process.poll())


if __name__ == '__main__':
    unittest.main(verbosity=2)
