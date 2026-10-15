"""No real data, credentials, servers or network: local Restic fixtures only."""

import io
import json
import os
from pathlib import Path
import sqlite3
import subprocess
import sys
import tarfile
import tempfile
import unittest


PRODUCER = Path(sys.argv.pop(1))


class BackupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.data = self.root / "data"
        (self.data / "db").mkdir(parents=True)
        self.stage = self.root / "stage"
        self.database = sqlite3.connect(self.data / "db/memory.sqlite")
        self.addCleanup(self.database.close)
        self.database.execute("PRAGMA journal_mode=WAL")
        self.database.execute("CREATE TABLE evidence (value TEXT)")
        self.database.execute("INSERT INTO evidence VALUES ('committed-in-wal')")
        self.database.commit()
        self.files = ["raw/history.jsonl", "wiki/.git/fixture", "wiki/_pending/proposal.md", "auth.json", "extra/unknown"]
        for name in self.files + [".serve.lock", ".serve.lock.other"]:
            path = self.data / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("invented fixture only")
            path.chmod(0o600)
        self.environment = {**os.environ, "RESTIC_REPOSITORY": str(self.root / "restic"), "RESTIC_PASSWORD": "invented-fixture-password"}

    def producer(self):
        return [sys.executable, str(PRODUCER), "--source", str(self.data), "--staging", str(self.stage)]

    def restic(self, *args):
        return subprocess.run(["restic", *args], env=self.environment, capture_output=True)

    def test_full_stream_and_online_wal_snapshot(self):
        result = subprocess.run(self.producer(), capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        with tarfile.open(fileobj=io.BytesIO(result.stdout)) as archive:
            names = archive.getnames()
            for name in self.files:
                self.assertIn("data/" + name, names)
            self.assertNotIn("data/.serve.lock", names)
            self.assertNotIn("data/.serve.lock.other", names)
            self.assertNotIn("data/db/memory.sqlite-wal", names)
            self.assertNotIn("data/db/memory.sqlite-shm", names)
            copied = self.root / "copy.sqlite"
            copied.write_bytes(archive.extractfile("data/db/memory.sqlite").read())
            manifest = json.load(archive.extractfile("backup-manifest.json"))
            self.assertIn("non-atomic", manifest["filesystem"])
        with sqlite3.connect(copied) as database:
            self.assertEqual(database.execute("PRAGMA integrity_check").fetchone()[0], "ok")
            self.assertEqual(database.execute("SELECT value FROM evidence").fetchone()[0], "committed-in-wal")
        self.database.execute("INSERT INTO evidence VALUES ('writer-still-open')")
        self.database.commit()
        self.assertEqual(self.stage.stat().st_mode & 0o777, 0o700)
        self.assertEqual(list(self.stage.iterdir()), [])
        self.assertEqual((self.data / "auth.json").read_text(), "invented fixture only")

    def test_symlink_fails_without_reading_target(self):
        target = self.root / "private-fixture"
        target.write_text("MUST_NOT_BE_ARCHIVED")
        (self.data / "unsafe").symlink_to(target)
        result = subprocess.run(self.producer(), capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn(b"MUST_NOT_BE_ARCHIVED", result.stdout + result.stderr)
        self.assertEqual(list(self.stage.iterdir()), [])

    def test_symlink_directory_and_nested_staging_fail(self):
        (self.data / "unsafe-directory").symlink_to(self.root, target_is_directory=True)
        result = subprocess.run(self.producer(), capture_output=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(self.stage.iterdir()), [])
        nested = self.producer()
        nested[-1] = str(self.data / "nested-stage")
        self.assertNotEqual(subprocess.run(nested, capture_output=True).returncode, 0)
        self.assertFalse((self.data / "nested-stage").exists())

    def test_unexpected_database_fails_closed(self):
        with sqlite3.connect(self.data / "extra/another.sqlite") as database:
            database.execute("CREATE TABLE unexpected (value TEXT)")
        self.assertNotEqual(subprocess.run(self.producer(), capture_output=True).returncode, 0)
        self.assertEqual(list(self.stage.iterdir()), [])

    def test_native_restic_rejects_failed_producer_and_preserves_snapshot(self):
        self.assertEqual(self.restic("init").returncode, 0, "isolated fixture init failed")
        first = self.restic("backup", "--stdin-from-command", "--stdin-filename=ai-memory-full.tar", "--", *self.producer())
        self.assertEqual(first.returncode, 0, first.stderr)
        snapshots = json.loads(self.restic("snapshots", "--json").stdout)
        self.assertEqual(len(snapshots), 1)
        (self.data / "unsafe").symlink_to(self.root / "missing-fixture")
        failed = self.restic("backup", "--stdin-from-command", "--stdin-filename=ai-memory-full.tar", "--", *self.producer())
        self.assertNotEqual(failed.returncode, 0)
        self.assertEqual(json.loads(self.restic("snapshots", "--json").stdout), snapshots)


if __name__ == "__main__":
    unittest.main()
