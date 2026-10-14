"""Offline regression checks for the release catalog updater."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("updater", Path(__file__).with_name("update-releases.py"))
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)

class UpdateTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.path = Path(self.directory.name) / "releases.json"
        self.catalog = {name:{"version":"0.1.0", "sources":{"x86_64-linux":{}}, "release":"old"} for name in ("filmcraft", "photocraft")}
        self.original = json.dumps(self.catalog, indent=2) + "\n"
        self.path.write_text(self.original)

    def newer(self, name, previous, version):
        return {**previous, "version":"0.2.0"}

    def test_check_preserves_catalog(self):
        self.assertTrue(updater.update_catalog(self.path, ["filmcraft"], fetch=self.newer))
        self.assertEqual(self.path.read_text(), self.original)

    def test_write_updates_only_selected(self):
        updater.update_catalog(self.path, ["filmcraft"], write=True, fetch=self.newer)
        result = json.loads(self.path.read_text())
        self.assertEqual(result["filmcraft"]["version"], "0.2.0")
        self.assertEqual(result["photocraft"], self.catalog["photocraft"])

    def test_failure_never_writes_partial_batch(self):
        def fail(name, previous, version):
            if name == "photocraft":
                raise ValueError("missing ARM64 artifact")
            return self.newer(name, previous, version)
        with self.assertRaises(ValueError):
            updater.update_catalog(self.path, ["filmcraft", "photocraft"], write=True, fetch=fail)
        self.assertEqual(self.path.read_text(), self.original)

    def test_rejects_unknown_app_before_fetch(self):
        with self.assertRaises(ValueError):
            updater.update_catalog(self.path, ["unknown"], fetch=lambda *args:self.fail("fetch must not run"))

    def test_rejects_changed_catalog(self):
        def concurrent_edit(name, previous, version):
            self.path.write_text("concurrent change")
            return self.newer(name, previous, version)
        with self.assertRaises(ValueError):
            updater.update_catalog(self.path, ["filmcraft"], write=True, fetch=concurrent_edit)
        self.assertEqual(self.path.read_text(), "concurrent change")

    def test_explicit_version_requires_one_app(self):
        with self.assertRaises(ValueError):
            updater.update_catalog(self.path, list(self.catalog), version="0.2.0", fetch=self.newer)

    def test_refresh_matches_exact_app_not_cli_or_server(self):
        release = {
            "tag_name":"v0.2.0", "draft":False, "prerelease":False,
            "assets":[{"name":"filmcraft-0.2.0-linux-x86_64.tar.gz", "state":"uploaded",
                       "browser_download_url":"https://github.com/storytold/filmcraft/releases/download/v0.2.0/filmcraft-0.2.0-linux-x86_64.tar.gz", "digest":"sha256:"+"a"*64},
                      {"name":"filmcraft-cli-0.2.0-linux-x86_64.tar.gz", "state":"uploaded",
                       "browser_download_url":"wrong", "digest":"sha256:"+"b"*64}]
        }
        class Response:
            def __enter__(self): return self
            def __exit__(self, *args): pass
            def read(self): return json.dumps(release).encode()
        with patch.object(updater, "request", return_value=Response()):
            result = updater.refresh("filmcraft", self.catalog["filmcraft"])
        self.assertEqual(result["sources"]["x86_64-linux"]["sha256"], "a"*64)

    def test_missing_architecture_rejected(self):
        release = {"tag_name":"v0.2.0", "assets":[], "draft":False, "prerelease":False}
        class Response:
            def __enter__(self): return self
            def __exit__(self, *args): pass
            def read(self): return json.dumps(release).encode()
        with patch.object(updater, "request", return_value=Response()):
            with self.assertRaises(ValueError):
                updater.refresh("filmcraft", self.catalog["filmcraft"])

    def test_api_limit_uses_published_checksums(self):
        error = updater.urllib.error.HTTPError("https://api.github.com/", 403, "rate limit", {}, None)
        with patch.object(updater, "request", side_effect=error), \
             patch.object(updater, "latest_tag", return_value="v0.2.0"), \
             patch.object(updater, "checksums", return_value={"filmcraft-0.2.0-linux-x86_64.tar.gz":"c"*64}):
            result = updater.refresh("filmcraft", self.catalog["filmcraft"])
        self.assertEqual(result["version"], "0.2.0")
        self.assertEqual(result["sources"]["x86_64-linux"]["sha256"], "c"*64)

if __name__ == "__main__":
    unittest.main()

