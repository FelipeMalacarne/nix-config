import importlib.util
import json
import os
from pathlib import Path
import stat
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("settings", Path(__file__).with_name("settings.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class SettingsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.store = self.root / "store"
        self.store.mkdir()
        self.source = self.root / "incoming.json"
        self.settings = self.root / "claude/settings.json"
        self.baseline = self.settings.with_name("settings.nix.json")

    def write(self, path, data):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data))

    def update(self, data, **kwargs):
        self.write(self.source, data)
        module.update(self.source, self.settings, self.baseline, self.store, **kwargs)

    def test_first_activation_and_private_regular_file(self):
        self.update({"model": "fixture", "enabledPlugins": {"test": True}})
        self.assertFalse(self.settings.is_symlink())
        self.assertEqual(json.loads(self.settings.read_text()), json.loads(self.source.read_text()))
        self.assertEqual(stat.S_IMODE(self.settings.stat().st_mode), 0o600)
        # Reproduce Claude's realpath + adjacent temporary-file replacement.
        real = self.settings.resolve()
        temporary = real.with_suffix(".json.tmp.fixture")
        self.write(temporary, {"model": "fixture", "modelSettings": {"fixture": {"effortLevel": "high"}}})
        temporary.replace(real)
        self.assertEqual(json.loads(self.settings.read_text())["modelSettings"]["fixture"]["effortLevel"], "high")

    def test_rebuild_preserves_local_edits_and_updates_untouched_defaults(self):
        previous = {"model": "old", "env": {"ENDPOINT": "old"}, "enabledPlugins": {"old": True}}
        self.write(self.baseline, previous)
        self.write(self.settings, {**previous, "model": "personal", "effortLevel": "high"})
        incoming = {"model": "new", "env": {"ENDPOINT": "new"}, "enabledPlugins": {"new": True}}
        self.update(incoming)
        expected = {**incoming, "model": "personal", "effortLevel": "high"}
        self.assertEqual(json.loads(self.settings.read_text()), expected)
        self.write(self.baseline, incoming)
        before = self.settings.stat().st_mtime_ns
        self.update(incoming)
        self.assertEqual(self.settings.stat().st_mtime_ns, before)

    def test_nested_changes_deletions_and_array_overrides(self):
        previous = {"env": {"same": "old", "edit": "old", "deleted": "old"}, "permissions": {"ask": ["Read"]}}
        current = {"env": {"same": "old", "edit": "local", "local": "keep"}, "permissions": {"ask": []}}
        incoming = {"env": {"same": "new", "edit": "new", "deleted": "new", "added": "new"}, "permissions": {"ask": ["Write"]}}
        self.assertEqual(module.rebase(previous, current, incoming), {
            "env": {"same": "new", "edit": "local", "local": "keep", "added": "new"},
            "permissions": {"ask": []},
        })
        self.assertEqual(module.rebase({"env": {"old": 1}}, {"env": {"old": 1, "personal": 2}}, {}), {"env": {"personal": 2}})

    def test_existing_unmanaged_preferences_are_not_reset(self):
        self.write(self.settings, {"model": "personal", "effortLevel": "high", "env": {"personal": "keep"}})
        self.update({"model": "default", "env": {"endpoint": "fixture"}})
        self.assertEqual(json.loads(self.settings.read_text()), {
            "model": "personal", "effortLevel": "high", "env": {"personal": "keep", "endpoint": "fixture"},
        })

    def test_missing_settings_are_seeded_from_current_baseline(self):
        self.write(self.baseline, {"model": "old"})
        self.update({"model": "new"})
        self.assertEqual(json.loads(self.settings.read_text()), {"model": "new"})

    def test_home_manager_symlink_migration_never_changes_the_store(self):
        managed = self.store / "fixture-home-manager-files/.claude/settings.json"
        self.write(managed, {"model": "old", "enabledPlugins": {"test": True}})
        managed.chmod(0o444)
        self.settings.parent.mkdir()
        self.settings.symlink_to(managed)
        original = managed.read_bytes()
        self.update({"model": "new", "enabledPlugins": {"test": True}})
        self.assertFalse(self.settings.is_symlink())
        self.assertEqual(json.loads(self.settings.read_text())["model"], "new")
        self.assertEqual(managed.read_bytes(), original)
        self.assertEqual(stat.S_IMODE(managed.stat().st_mode), 0o444)

    def test_previous_home_manager_baseline_link(self):
        managed = self.store / "fixture-home-manager-files/.claude/settings.nix.json"
        self.write(managed, {"model": "old"})
        self.write(self.settings, {"model": "old", "effortLevel": "high"})
        self.baseline.symlink_to(managed)
        self.update({"model": "new"})
        self.assertEqual(json.loads(self.settings.read_text()), {"model": "new", "effortLevel": "high"})

    def test_check_and_dry_run_are_read_only(self):
        self.update({"model": "new"}, check=True)
        self.assertFalse(self.settings.parent.exists())

    def test_malformed_settings_or_baseline_are_not_overwritten(self):
        for path in [self.settings, self.baseline]:
            for content in ["invalid private content", "[]", "null"]:
                self.write(self.settings, {"effortLevel": "high"})
                self.write(self.baseline, {})
                path.write_text(content)
                original = self.settings.read_bytes()
                with self.assertRaises((ValueError, json.JSONDecodeError)):
                    self.update({"model": "new"})
                self.assertEqual(self.settings.read_bytes(), original)

    def test_foreign_and_broken_symlinks_are_not_replaced(self):
        self.settings.parent.mkdir()
        for target in [self.root / "foreign.json", self.store / "not-home-manager/settings.json"]:
            self.settings.symlink_to(target)
            with self.assertRaises((ValueError, FileNotFoundError)):
                self.update({"model": "new"})
            self.assertTrue(self.settings.is_symlink())
            self.settings.unlink()

    def test_store_directory_and_writer_lock_are_rejected(self):
        self.settings.parent.symlink_to(self.store, target_is_directory=True)
        with self.assertRaises(ValueError):
            self.update({"model": "new"})
        self.settings.parent.unlink()
        self.settings.parent.mkdir()
        lock = self.settings.with_name(".nix-settings.lock")
        lock.mkdir()
        with self.assertRaises(FileExistsError):
            self.update({"model": "new"})
        self.assertTrue(lock.is_dir())
        self.assertFalse(self.settings.exists())

    def test_concurrent_change_is_not_overwritten(self):
        self.write(self.settings, {"model": "old"})
        original_read = module.read_settings
        reads = 0

        def read(path, store):
            nonlocal reads
            if path == self.settings:
                reads += 1
                if reads == 3:
                    self.write(self.settings, {"model": "concurrent"})
            return original_read(path, store)

        with patch.object(module, "read_settings", side_effect=read):
            with self.assertRaises(RuntimeError):
                self.update({"model": "new"})
        self.assertEqual(json.loads(self.settings.read_text()), {"model": "concurrent"})
        self.assertEqual(list(self.settings.parent.glob(".nix-settings-*")), [])
        self.assertFalse(self.settings.with_name(".nix-settings.lock").exists())

    def test_failed_atomic_publish_does_not_damage_existing_settings(self):
        self.write(self.settings, {"model": "old"})
        original = self.settings.read_bytes()
        with patch.object(module.os, "replace", side_effect=OSError("synthetic publish failure")):
            with self.assertRaises(OSError):
                self.update({"model": "new"})
        self.assertEqual(self.settings.read_bytes(), original)
        self.assertEqual(list(self.settings.parent.glob(".nix-settings-*")), [])
        self.assertFalse(self.settings.with_name(".nix-settings.lock").exists())

    def test_special_files_are_rejected_without_blocking(self):
        self.settings.parent.mkdir()
        os.mkfifo(self.settings)
        with self.assertRaises(ValueError):
            self.update({"model": "new"})
        self.settings.unlink()
        self.settings.mkdir()
        with self.assertRaises(ValueError):
            self.update({"model": "new"})


if __name__ == "__main__":
    unittest.main()
