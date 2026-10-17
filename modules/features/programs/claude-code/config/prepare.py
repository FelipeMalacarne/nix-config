"""Merge explicitly selected Remote Control consent into Claude's mutable state."""

import json
import os
from pathlib import Path
import sys
import tempfile


def prepare(state: Path, directory: Path) -> None:
    directory = directory.resolve(strict=True)
    if not directory.is_dir():
        raise ValueError("Remote Control workspace must be a directory")
    if state.is_symlink():
        raise ValueError("Refusing to replace symlinked Claude state")
    state.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    # Claude uses proper-lockfile's adjacent .lock directory. Fail rather than
    # race another writer or guess when its lock can safely be removed.
    lock = Path(str(state) + ".lock")
    lock.mkdir(mode=0o700)
    temporary = None
    try:
        original = state.read_bytes() if state.exists() else None
        data = json.loads(original) if original is not None else {}
        if not isinstance(data, dict):
            raise ValueError("Claude state must be an object")
        projects = data.setdefault("projects", {})
        if not isinstance(projects, dict):
            raise ValueError("Claude projects must be an object")
        project = projects.setdefault(str(directory), {})
        if not isinstance(project, dict):
            raise ValueError("Claude project must be an object")
        if project.get("hasTrustDialogAccepted") is True and data.get("remoteDialogSeen") is True:
            return
        project["hasTrustDialogAccepted"] = True
        data["remoteDialogSeen"] = True
        with tempfile.NamedTemporaryFile(dir=state.parent, prefix=".claude-rc-", delete=False) as stream:
            temporary = Path(stream.name)
            stream.write((json.dumps(data, indent=2) + "\n").encode())
            stream.flush()
            os.fsync(stream.fileno())
        if state.is_symlink() or (state.read_bytes() if state.exists() else None) != original:
            raise RuntimeError("Claude state changed concurrently; refusing to overwrite")
        os.replace(temporary, state)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
        lock.rmdir()


if __name__ == "__main__":
    try:
        prepare(Path(sys.argv[1]), Path(sys.argv[2]))
    except Exception:
        # State may contain credentials: never include its contents or parser
        # exception details in service logs.
        sys.exit("Cannot prepare Claude Remote Control state; check directory, JSON validity and lock ownership privately.")
