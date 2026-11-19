"""Initialize writable Hermes state without replacing existing files."""

import argparse
import os
from pathlib import Path
import secrets
import stat
import tempfile


def publish_once(destination: Path, content: bytes) -> None:
    """Publish a complete, private file atomically, without clobbering a peer."""
    destination.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    fd, temporary = tempfile.mkstemp(prefix=".hermes-init-", dir=destination.parent)
    try:
        with os.fdopen(fd, "wb") as stream:
            stream.write(content)
        try:
            os.link(temporary, destination)
        except FileExistsError:
            pass
    finally:
        os.unlink(temporary)


def seed_skill(source: Path, destination: Path) -> None:
    # Even a symlink is an existing user choice, not permission to replace it.
    if not destination.exists() and not destination.is_symlink():
        publish_once(destination, source.read_bytes())


def ensure_token(destination: Path) -> None:
    publish_once(destination, (secrets.token_hex(32) + "\n").encode("ascii"))
    # Do not follow a symlink or block on a FIFO. Never log or return the token.
    fd = os.open(destination, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
    try:
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode) or info.st_uid != os.geteuid() or info.st_size == 0:
            raise ValueError("token must be a nonempty regular file owned by the current user")
        os.fchmod(fd, 0o600)
    finally:
        os.close(fd)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    seed = commands.add_parser("seed-skill")
    seed.add_argument("source", type=Path)
    seed.add_argument("destination", type=Path)
    token = commands.add_parser("ensure-token")
    token.add_argument("destination", type=Path)
    args = parser.parse_args()
    try:
        if args.command == "seed-skill":
            seed_skill(args.source, args.destination)
        else:
            ensure_token(args.destination)
    except (OSError, ValueError) as error:
        parser.exit(1, f"Hermes runtime setup failed: {error}\n")


if __name__ == "__main__":
    main()
