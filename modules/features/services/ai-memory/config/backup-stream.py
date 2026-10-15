"""Stream full ai-memory data, substituting an online SQLite snapshot.

Only intended as Restic's --stdin-from-command producer. No plaintext archive
is saved locally. Filesystem files are copied live, NOT atomically with SQLite.
"""

import argparse
import io
import json
import os
from pathlib import Path
import sqlite3
import stat
import sys
import tarfile
import tempfile
import time


DATABASE = Path("db/memory.sqlite")
SIDECARS = {str(DATABASE) + suffix for suffix in ("-wal", "-shm", "-journal")}


def unchanged(before, after):
    return (before.st_ino, before.st_dev, before.st_size, before.st_mtime_ns) == (
        after.st_ino, after.st_dev, after.st_size, after.st_mtime_ns
    )


def snapshot_database(source, destination):
    deadline = time.monotonic() + 120

    def progress(_status, _remaining, _total):
        if time.monotonic() > deadline:
            raise RuntimeError("Database snapshot exceeded its time budget")

    live = sqlite3.connect(source.as_uri() + "?mode=ro", uri=True, timeout=5)
    snapshot = sqlite3.connect(destination)
    try:
        live.backup(snapshot, pages=128, progress=progress, sleep=0.05)
        snapshot.set_progress_handler(lambda: int(time.monotonic() > deadline), 10000)
        if snapshot.execute("PRAGMA quick_check").fetchall() != [("ok",)]:
            raise RuntimeError("Database snapshot failed integrity validation")
    finally:
        snapshot.close()
        live.close()
    os.chmod(destination, 0o600)


def add_regular(archive, source, name, metadata=None, directory=None):
    descriptor = os.open(source, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=directory)
    with os.fdopen(descriptor, "rb") as stream:
        before = os.fstat(stream.fileno())
        if not stat.S_ISREG(before.st_mode):
            raise RuntimeError("Unexpected non-regular data file")
        if metadata is None and stream.read(16) == b"SQLite format 3\0":
            raise RuntimeError("Unexpected additional database requires review")
        stream.seek(0)
        original = metadata or before
        info = tarfile.TarInfo(name)
        info.size = before.st_size
        info.mode = stat.S_IMODE(original.st_mode)
        info.uid, info.gid = original.st_uid, original.st_gid
        info.mtime = original.st_mtime
        archive.addfile(info, stream)
        after = os.stat(source, dir_fd=directory, follow_symlinks=False)
        if not unchanged(before, os.fstat(stream.fileno())) or not unchanged(before, after):
            raise RuntimeError("Data changed while archiving; retry the backup")


def stream_backup(source, staging, output):
    os.umask(0o077)
    if source == Path("/") or not source.is_absolute() or source.is_symlink() or not source.is_dir():
        raise RuntimeError("Source must be an existing absolute, non-symlink directory")
    if source.resolve() != source or staging.resolve() != staging:
        raise RuntimeError("Source and staging ancestors must not be symlinks")
    if source == staging or source in staging.parents or staging in source.parents:
        raise RuntimeError("Source and staging trees must be separate")
    staging.mkdir(mode=0o700, parents=True, exist_ok=True)
    state = staging.lstat()
    if state.st_uid != os.getuid() or stat.S_IMODE(state.st_mode) != 0o700:
        raise RuntimeError("Staging must be owned by the backup user with mode 0700")
    database = source / DATABASE
    database_metadata = database.lstat()
    if not stat.S_ISREG(database_metadata.st_mode):
        raise RuntimeError("Database must be a regular file")
    started = time.time()
    with tempfile.TemporaryDirectory(prefix="sqlite-", dir=staging) as temporary:
        snapshot = Path(temporary) / "memory.sqlite"
        snapshot_database(database, snapshot)
        with tarfile.open(fileobj=output, mode="w|", format=tarfile.PAX_FORMAT) as archive:
            def fail_walk(error):
                raise error

            for directory, directories, files, descriptor in os.fwalk(source, follow_symlinks=False, onerror=fail_walk):
                base = Path(directory)
                for name in sorted(directories):
                    entry = base / name
                    metadata = os.stat(name, dir_fd=descriptor, follow_symlinks=False)
                    if not stat.S_ISDIR(metadata.st_mode):
                        raise RuntimeError("Symlink directories require a reviewed backup policy")
                    info = tarfile.TarInfo(str(Path("data") / entry.relative_to(source)))
                    info.type = tarfile.DIRTYPE
                    info.mode = stat.S_IMODE(metadata.st_mode)
                    info.uid, info.gid = metadata.st_uid, metadata.st_gid
                    info.mtime = metadata.st_mtime
                    archive.addfile(info)
                for name in sorted(files):
                    entry = base / name
                    relative = entry.relative_to(source)
                    if relative == DATABASE or str(relative) in SIDECARS:
                        continue
                    if relative.parent == Path(".") and (name == ".serve.lock" or name.startswith(".serve.lock.")):
                        continue
                    if relative.parent == Path("db") and entry.suffix in (".sqlite", ".sqlite3", ".db"):
                        raise RuntimeError("Unexpected additional database requires review")
                    add_regular(archive, name, str(Path("data") / relative), directory=descriptor)
            add_regular(archive, snapshot, "data/db/memory.sqlite", database_metadata)
            manifest = json.dumps({
                "format": 1,
                "started_at": started,
                "finished_at": time.time(),
                "database": "online SQLite backup, quick_check passed",
                "filesystem": "live non-atomic copy; not a whole-dataset point-in-time snapshot",
                "excluded": sorted(SIDECARS | {".serve.lock", ".serve.lock.*"}),aimem
                "credentials": "in-directory files only; external SOPS credentials/age keys are not included",
            }).encode()
            info = tarfile.TarInfo("backup-manifest.json")
            info.size, info.mode = len(manifest), 0o600
            archive.addfile(info, io.BytesIO(manifest))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--staging", type=Path, required=True)
    args = parser.parse_args()
    try:
        stream_backup(args.source, args.staging, sys.stdout.buffer)
    except (OSError, RuntimeError, sqlite3.Error, tarfile.TarError):
        # Source data and arbitrary filesystem/provider error strings are private.
        print("ai-memory backup producer failed; no successful snapshot should be accepted", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
