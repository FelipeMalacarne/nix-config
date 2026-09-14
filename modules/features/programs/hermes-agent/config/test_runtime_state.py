"""Exercise only disposable state; never use the operator's Hermes home."""

from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("runtime-state.py")
SKILL = Path(__file__).parent / "nix-system-workflow" / "SKILL.md"


class RuntimeStateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def run_setup(self, *args):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), *map(str, args)],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "")

    def test_seed_is_a_writable_copy_and_preserves_learning(self):
        source = self.root / "seed.md"
        source.write_text("Original workflow\n")
        source.chmod(0o444)
        target = self.root / "skills" / "nix-system-workflow" / "SKILL.md"
        self.run_setup("seed-skill", source, target)
        self.assertFalse(target.is_symlink())
        self.assertEqual(target.read_text(), source.read_text())
        self.assertEqual(target.stat().st_mode & 0o777, 0o600)
        target.write_text("Locally learned procedure\n")
        source.chmod(0o600)
        source.write_text("New upstream seed\n")
        self.run_setup("seed-skill", source, target)
        self.assertEqual(target.read_text(), "Locally learned procedure\n")

    def test_token_is_private_and_stable_across_rebuilds(self):
        target = self.root / ".backend-session-token"
        self.run_setup("ensure-token", target)
        original = target.read_bytes()
        self.assertRegex(original.decode(), r"^[a-f0-9]{64}\n$")
        self.assertEqual(target.stat().st_mode & 0o777, 0o600)
        target.chmod(0o644)
        self.run_setup("ensure-token", target)
        self.assertEqual(target.read_bytes(), original)
        self.assertEqual(target.stat().st_mode & 0o777, 0o600)

    def test_token_creation_is_safe_under_concurrent_activation(self):
        target = self.root / "private" / ".backend-session-token"
        with ThreadPoolExecutor(max_workers=8) as executor:
            results = list(executor.map(
                lambda _: subprocess.run(
                    [sys.executable, str(SCRIPT), "ensure-token", str(target)],
                    capture_output=True,
                    text=True,
                    timeout=10,
                ),
                range(8),
            ))
        for result in results:
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, "")
        self.assertRegex(target.read_text(), r"^[a-f0-9]{64}\n$")
        self.assertEqual(list(target.parent.glob(".hermes-init-*")), [])

    def test_existing_empty_token_and_symlink_are_rejected(self):
        target = self.root / "token"
        target.touch()
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "ensure-token", str(target)],
            capture_output=True,
            timeout=10,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(target.read_bytes(), b"")
        target.unlink()
        other = self.root / "other"
        other.write_text("Unrelated file\n")
        other.chmod(0o644)
        target.symlink_to(other)
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "ensure-token", str(target)],
            capture_output=True,
            timeout=10,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(other.read_text(), "Unrelated file\n")
        self.assertEqual(other.stat().st_mode & 0o777, 0o644)


if __name__ == "__main__":
    unittest.main()
