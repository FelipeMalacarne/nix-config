"""Rebase writable Claude preferences onto Home Manager's settings baseline."""

import copy
import json
import os
from pathlib import Path
import stat
import sys
import tempfile


MISSING = object()


def rebase(previous, current, incoming):
    """Update unchanged defaults; preserve edits, additions and deletions."""
    if current == previous:
        return MISSING if incoming is MISSING else copy.deepcopy(incoming)
    if isinstance(current, dict) and (previous is MISSING or isinstance(previous, dict)) and (
        incoming is MISSING or isinstance(incoming, dict)
    ):
        before = {} if previous is MISSING else previous
        after = {} if incoming is MISSING else incoming
        result = copy.deepcopy(current)
        for key in before.keys() | after.keys():
            value = rebase(before.get(key, MISSING), current.get(key, MISSING), after.get(key, MISSING))
            if value is MISSING:
                result.pop(key, None)
            else:
                result[key] = value
        return MISSING if incoming is MISSING and not result else result
    return MISSING if current is MISSING else copy.deepcopy(current)


def read_settings(path, store):
    """Read regular files or recognized Home Manager links, never arbitrary links."""
    try:
        info = path.lstat()
    except FileNotFoundError:
        return {}, None
    original = path
    if stat.S_ISLNK(info.st_mode):
        target = Path(os.readlink(path))
        parts = target.relative_to(store).parts
        if len(parts) < 3 or not parts[0].endswith("-home-manager-files") or parts[-1] != path.name:
            raise ValueError("Not a Home Manager settings link")
        path = target.resolve(strict=True)
        if not path.is_relative_to(store.resolve()):
            raise ValueError("Settings link escapes the store")
    fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        if not stat.S_ISREG(os.fstat(fd).st_mode):
            raise ValueError("Settings must be a regular file")
        with os.fdopen(fd, "rb", closefd=False) as stream:
            content = stream.read()
    finally:
        os.close(fd)
    data = json.loads(content)
    if not isinstance(data, dict):
        raise ValueError("Settings must be a JSON object")
    # Include the link/file identity as well as its contents in the write guard.
    identity = (info.st_dev, info.st_ino, info.st_mode, info.st_size, info.st_mtime_ns, info.st_ctime_ns)
    return data, (identity, content, os.readlink(original) if original.is_symlink() else None)


def update(source, settings, baseline, store=Path("/nix/store"), *, check=False):
    incoming = json.loads(source.read_bytes())
    if not isinstance(incoming, dict):
        raise ValueError("Baseline must be a JSON object")
    if settings.parent.resolve().is_relative_to(store.resolve()):
        raise ValueError("Settings directory must be writable outside the store")
    current, original = read_settings(settings, store)
    previous, old_baseline = read_settings(baseline, store)
    if original is None:
        previous = {}
    elif old_baseline is None and settings.is_symlink():
        # The pre-migration symlink is itself an unmodified declarative baseline.
        previous = current
    result = rebase(previous, current, incoming)
    if check:
        return
    settings.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    lock = settings.with_name(".nix-settings.lock")
    lock.mkdir(mode=0o700)
    temporary = None
    try:
        if read_settings(settings, store)[1] != original or read_settings(baseline, store)[1] != old_baseline:
            raise RuntimeError("Settings changed concurrently")
        if (
            result == current
            and original is not None
            and not settings.is_symlink()
            and stat.S_IMODE(settings.stat().st_mode) == 0o600
        ):
            return
        with tempfile.NamedTemporaryFile(dir=settings.parent, prefix=".nix-settings-", delete=False) as stream:
            temporary = Path(stream.name)
            stream.write((json.dumps(result, indent=2) + "\n").encode())
            stream.flush()
            os.fsync(stream.fileno())
        if read_settings(settings, store)[1] != original or read_settings(baseline, store)[1] != old_baseline:
            raise RuntimeError("Settings changed concurrently")
        os.replace(temporary, settings)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
        lock.rmdir()


if __name__ == "__main__":
    try:
        update(*(Path(arg) for arg in sys.argv[1:5]), check="--check" in sys.argv[5:])
    except Exception:
        # Runtime settings may contain private values; do not print parser errors.
        sys.exit("Cannot update Claude settings; check JSON, symlink ownership and concurrent writers privately.")
