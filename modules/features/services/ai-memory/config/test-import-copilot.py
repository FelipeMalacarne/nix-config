"""Exercise the operator importer with isolated, invented credentials only."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


IMPORTER = Path(sys.argv.pop(1))
TOKEN = "ghu_fixtureBootstrapToken123"
OTHER = "fixtureOtherProviderDoNotImport"
CACHED = "fixtureShortLivedCopilotToken"


class ImportTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / "flake.nix").write_text("{}")
        (self.root / "secrets").mkdir()
        key = self.root / "fixture-age.key"
        subprocess.run(["age-keygen", "-o", str(key)], check=True, capture_output=True)
        public = subprocess.run(["age-keygen", "-y", str(key)], check=True, capture_output=True, text=True).stdout.strip()
        (self.root / ".sops.yaml").write_text(json.dumps({
            "creation_rules": [{"path_regex": r"secrets/.*\.yaml$", "age": public}],
        }))
        self.env = {**os.environ, "SOPS_AGE_KEY_FILE": str(key)}
        self.env.pop("SOPS_AGE_KEY", None)
        self.auth = self.root / "auth.json"
        self.destination = self.root / "secrets/ai-memory-copilot.yaml"
        self.destination.write_text("existing-ciphertext-marker\n")
        self.write_auth()

    def write_auth(self, entry=None):
        self.auth.write_text(json.dumps({
            "openai": {"refresh": OTHER},
            "copilot": entry if entry is not None else {
                "type": "oauth", "github_access": TOKEN, "copilot_access": CACHED,
            },
        }))

    def run_import(self, confirm=True, env=None):
        args = [sys.executable, str(IMPORTER), "--auth-file", str(self.auth)]
        if confirm:
            args.append("--confirm")
        result = subprocess.run(args, cwd=self.root, env=env or self.env, text=True, capture_output=True)
        for value in [TOKEN, OTHER, CACHED]:
            self.assertNotIn(value, result.stdout + result.stderr)
        return result

    def assert_preserved(self, result):
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.destination.read_text(), "existing-ciphertext-marker\n")
        self.assertEqual(list((self.root / "secrets").glob(".ai-memory-copilot-*")), [])

    def test_preview_never_reads_credentials(self):
        self.auth.unlink()
        result = self.run_import(confirm=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("no credentials read", result.stdout)
        self.assertEqual(self.destination.read_text(), "existing-ciphertext-marker\n")

    def test_encrypts_only_bootstrap_and_preserves_source(self):
        source = self.auth.read_bytes()
        result = self.run_import()
        self.assertEqual(result.returncode, 0, result.stderr)
        ciphertext = self.destination.read_text()
        for value in [TOKEN, OTHER, CACHED]:
            self.assertNotIn(value, ciphertext)
        decoded = subprocess.run([
            "sops", "--decrypt", "--output-type", "json", str(self.destination),
        ], env=self.env, check=True, capture_output=True, text=True)
        self.assertEqual(json.loads(decoded.stdout), {"github_token": TOKEN})
        self.assertEqual(self.destination.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.auth.read_bytes(), source)
        self.assertEqual(list((self.root / "secrets").glob(".ai-memory-copilot-*")), [])

    def test_rejects_cached_token_without_bootstrap(self):
        self.write_auth({"copilot_access": CACHED})
        self.assert_preserved(self.run_import())

    def test_accepts_oauth_app_token(self):
        self.write_auth({"github_access": "gho_fixtureOAuthApp"})
        result = self.run_import()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("gho_fixtureOAuthApp", result.stdout + result.stderr + self.destination.read_text())

    def test_rejects_expired_bootstrap(self):
        self.write_auth({"github_access": TOKEN, "github_expires": 1})
        self.assert_preserved(self.run_import())

    def test_rejects_environment_injection(self):
        self.write_auth({"github_access": TOKEN + "\nOTHER=value"})
        self.assert_preserved(self.run_import())

    def test_malformed_json_never_echoes_content(self):
        self.auth.write_text("malformed " + TOKEN)
        self.assert_preserved(self.run_import())

    def test_symlink_destination_is_untouched(self):
        target = self.root / "unrelated"
        target.write_text("preserve-me")
        self.destination.unlink()
        self.destination.symlink_to(target)
        self.assertNotEqual(self.run_import().returncode, 0)
        self.assertTrue(self.destination.is_symlink())
        self.assertEqual(target.read_text(), "preserve-me")

    def fake_sops(self, exit_code):
        tools = self.root / "tools"
        tools.mkdir()
        fake = tools / "sops"
        # Even a failed encryptor that echoes plaintext must not leak via the importer.
        fake.write_text(f"#!{sys.executable}\nimport sys\nvalue = sys.stdin.read()\n"
                        f"print(value, file=sys.{'stderr' if exit_code else 'stdout'})\n"
                        f"sys.exit({exit_code})\n")
        fake.chmod(0o700)
        return {**self.env, "PATH": str(tools) + os.pathsep + self.env["PATH"]}

    def test_encryption_failure_is_redacted_and_preserves_destination(self):
        self.assert_preserved(self.run_import(env=self.fake_sops(1)))

    def test_plaintext_encryptor_output_is_never_saved(self):
        self.assert_preserved(self.run_import(env=self.fake_sops(0)))


if __name__ == "__main__":
    unittest.main()
