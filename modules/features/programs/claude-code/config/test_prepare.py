import importlib.util
import json
from pathlib import Path
import stat
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("prepare", Path(__file__).with_name("prepare.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PrepareTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.state = self.root / ".claude.json"
        self.workspace = self.root / "repos"
        self.workspace.mkdir()

    def test_merge_preserves_existing_state_and_is_idempotent(self):
        original = {"oauthAccount": {"synthetic": "preserve"}, "projects": {"/other": {"hasTrustDialogAccepted": False}, str(self.workspace): {"allowedTools": ["Read"]}}}
        self.state.write_text(json.dumps(original))
        module.prepare(self.state, self.workspace)
        result = json.loads(self.state.read_text())
        self.assertEqual(result["oauthAccount"], original["oauthAccount"])
        self.assertEqual(result["projects"]["/other"], original["projects"]["/other"])
        self.assertEqual(result["projects"][str(self.workspace)]["allowedTools"], ["Read"])
        self.assertTrue(result["projects"][str(self.workspace)]["hasTrustDialogAccepted"])
        self.assertTrue(result["remoteDialogSeen"])
        self.assertEqual(stat.S_IMODE(self.state.stat().st_mode), 0o600)
        before = self.state.stat().st_mtime_ns
        module.prepare(self.state, self.workspace)
        self.assertEqual(self.state.stat().st_mtime_ns, before)

    def test_new_state(self):
        module.prepare(self.state, self.workspace)
        self.assertTrue(json.loads(self.state.read_text())["remoteDialogSeen"])

    def test_invalid_state_is_not_overwritten(self):
        for contents in ["invalid", "[]", '{"projects": []}']:
            self.state.write_text(contents)
            with self.assertRaises(ValueError):
                module.prepare(self.state, self.workspace)
            self.assertEqual(self.state.read_text(), contents)
            self.assertFalse(Path(str(self.state) + ".lock").exists())

    def test_symlink_is_not_replaced(self):
        target = self.root / "target"
        target.write_text("{}")
        self.state.symlink_to(target)
        with self.assertRaises(ValueError):
            module.prepare(self.state, self.workspace)
        self.assertTrue(self.state.is_symlink())
        self.assertEqual(target.read_text(), "{}")

    def test_existing_lock_is_respected(self):
        lock = Path(str(self.state) + ".lock")
        lock.mkdir()
        with self.assertRaises(FileExistsError):
            module.prepare(self.state, self.workspace)
        self.assertTrue(lock.is_dir())
        self.assertFalse(self.state.exists())


if __name__ == "__main__":
    unittest.main()
