"""Operator-only import: GitHub bootstrap token -> SOPS, never stdout or argv.

Run from the nix-config root in a private terminal, not a captured agent session.
The source auth file and the server's mutable token cache are never modified.
"""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time


class ImportFailure(Exception):
    pass


def default_auth_file():
    if sys.platform == "darwin":
        return Path.home() / "Library/Application Support/ai-memory/auth.json"
    return Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share") / "ai-memory/auth.json"


def import_token(auth_file, root):
    destination = root / "secrets/ai-memory-copilot.yaml"
    if destination.is_symlink():
        raise ImportFailure("Refusing a symlink destination; no file changed.")
    try:
        with auth_file.open("rb") as source:
            raw = source.read(1024 * 1024 + 1)
        if len(raw) > 1024 * 1024:
            raise ImportFailure("Auth file is unexpectedly large; no file changed.")
        auth = json.loads(raw)
        entry = auth.get("copilot", {})
        token = entry.get("github_access")
        expires = entry.get("github_expires")
        if not isinstance(token, str) or not re.fullmatch(r"(?:gh[opu]_|github_pat_)[A-Za-z0-9_]+", token):
            raise ImportFailure("No valid GitHub bootstrap token; run ai-memory auth login copilot first.")
        if expires is not None and (
            type(expires) is not int or expires <= time.time() * 1000
        ):
            raise ImportFailure("GitHub login is expired; log in again before importing.")
    except (OSError, ValueError, AttributeError, TypeError):
        # Never echo source content or a parser/subprocess diagnostic containing it.
        raise ImportFailure("Cannot read valid Copilot login data; no file changed.") from None

    result = subprocess.run(
        [
            "sops", "--config", str(root / ".sops.yaml"), "--encrypt",
            "--input-type", "json", "--output-type", "yaml",
            "--filename-override", str(destination), "/dev/stdin",
        ],
        input=json.dumps({"github_token": token}).encode(),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
        cwd=root,
    )
    if result.returncode != 0:
        raise ImportFailure("SOPS encryption failed; check the public recipient configuration. No file changed.")
    if token.encode() in result.stdout or b"ENC[" not in result.stdout or b"sops:" not in result.stdout:
        raise ImportFailure("SOPS did not return encrypted output; no file changed.")

    # Only ciphertext touches a temporary file, next to the destination for atomic replacement.
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(prefix=".ai-memory-copilot-", dir=destination.parent, delete=False) as out:
            temporary = Path(out.name)
            os.chmod(temporary, 0o600)
            out.write(result.stdout)
            out.flush()
            os.fsync(out.fileno())
        os.replace(temporary, destination)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--auth-file", type=Path, default=default_auth_file())
    parser.add_argument("--confirm", action="store_true", help="Read the login and replace the encrypted Copilot secret")
    args = parser.parse_args()
    root = Path.cwd()
    if not (root / "flake.nix").is_file() or not (root / ".sops.yaml").is_file() or not (root / "secrets").is_dir():
        parser.error("Run from the nix-config root containing flake.nix, .sops.yaml and secrets/.")
    if not args.confirm:
        print("Preview only: no credentials read or files changed.")
        print("Review .sops.yaml recipients, then add --confirm in your own private terminal.")
        print("Destination: secrets/ai-memory-copilot.yaml (encrypted github_token only).")
        return 0
    try:
        destination = import_token(args.auth_file, root)
    except (ImportFailure, OSError, subprocess.SubprocessError) as error:
        # Report known safe messages, never arbitrary OS/subprocess output.
        print(str(error) if isinstance(error, ImportFailure) else "Import failed; no credentials were printed.", file=sys.stderr)
        return 1
    print(f"Saved encrypted bootstrap credential to {destination.name}.")
    print("The source login is unchanged. Review ciphertext, commit it, and arrange approved deployment separately.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
