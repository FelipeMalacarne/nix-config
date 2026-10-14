"""Refresh pinned Craft release metadata; network reads occur only on invocation."""
import argparse
import concurrent.futures
import difflib
import json
import os
from pathlib import Path
import re
import tempfile
import urllib.error
import urllib.parse
import urllib.request

CATALOG = Path("modules/features/applications/artcraft/config/releases.json")
HEX256 = re.compile(r"[0-9a-fA-F]{64}")

def request(url, *, api=False):
    headers = {"User-Agent":"nix-config-artcraft-updater"}
    if api:
        headers["Accept"] = "application/vnd.github+json"
        token = os.environ.get("GITHUB_TOKEN")
        if token:
            headers["Authorization"] = f"Bearer {token}"
    return urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=30)

def latest_tag(name):
    with request(f"https://github.com/storytold/{name}/releases/latest") as response:
        prefix = f"https://github.com/storytold/{name}/releases/tag/"
        url = response.geturl()
        if not url.startswith(prefix):
            raise ValueError(f"{name}: latest release did not resolve to a release tag")
        return urllib.parse.unquote(url[len(prefix):])

def checksums(name, tag):
    url = f"https://github.com/storytold/{name}/releases/download/{tag}/SHA256SUMS.txt"
    with request(url) as response:
        text = response.read().decode("utf-8")
    found = {}
    for line in text.splitlines():
        fields = line.split(maxsplit=1)
        if len(fields) == 2 and HEX256.fullmatch(fields[0]):
            filename = fields[1].lstrip("*")
            if filename in found:
                raise ValueError(f"{name}: duplicate checksum for {filename}")
            found[filename] = fields[0].lower()
    return found

def refresh(name, previous, version=None):
    endpoint = "latest" if version is None else f"tags/v{version.removeprefix('v')}"
    data = None
    try:
        with request(f"https://api.github.com/repos/storytold/{name}/releases/{endpoint}", api=True) as response:
            data = json.load(response)
    except urllib.error.HTTPError as error:
        if error.code not in (403, 429, 500, 502, 503, 504):
            raise
    except urllib.error.URLError:
        # The public release redirect and checksum file do not consume API quota.
        pass
    tag = data["tag_name"] if data else (latest_tag(name) if version is None else f"v{version.removeprefix('v')}")
    if not re.fullmatch(r"v?[0-9][A-Za-z0-9.+_-]*", tag):
        raise ValueError(f"{name}: unsupported release tag {tag!r}")
    if data and (data.get("draft") or (version is None and data.get("prerelease"))):
        raise ValueError(f"{name}: release is not a published stable release")
    selected_version = tag.removeprefix("v")
    sources = {}
    published = None
    for system in previous["sources"]:
        arch = system.removesuffix("-linux")
        filename = f"{name}-{selected_version}-linux-{arch}.tar.gz"
        expected_url = f"https://github.com/storytold/{name}/releases/download/{tag}/{filename}"
        digest = None
        if data:
            matches = [asset for asset in data.get("assets", []) if asset["name"] == filename]
            if len(matches) != 1 or matches[0].get("state") != "uploaded":
                raise ValueError(f"{name}: missing or ambiguous uploaded artifact {filename}")
            asset = matches[0]
            if asset["browser_download_url"] != expected_url:
                raise ValueError(f"{name}: unexpected download URL for {filename}")
            value = asset.get("digest") or ""
            if value.startswith("sha256:") and HEX256.fullmatch(value[7:]):
                digest = value[7:].lower()
        if digest is None:
            if published is None:
                published = checksums(name, tag)
            digest = published.get(filename)
            if digest is None:
                raise ValueError(f"{name}: published SHA-256 missing for {filename}")
        sources[system] = {"sha256":digest, "url":expected_url}
    result = dict(previous)
    result.update(version=selected_version, release=f"https://github.com/storytold/{name}/releases/tag/{tag}", sources=sources)
    return result

def update_catalog(path, apps, *, write=False, version=None, fetch=refresh):
    original = path.read_text()
    catalog = json.loads(original)
    unknown = set(apps) - catalog.keys()
    if unknown:
        raise ValueError("Unknown Craft apps: " + ", ".join(sorted(unknown)))
    if version and len(apps) != 1:
        raise ValueError("--version requires exactly one app")
    result = dict(catalog)
    # Fetch everything before writing; one broken release leaves the catalog intact.
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        future = {name:executor.submit(fetch, name, catalog[name], version) for name in apps}
        for name in apps:
            result[name] = future[name].result()
    changed = [name for name in apps if catalog[name] != result[name]]
    if not changed:
        print("Selected Craft apps are up to date.")
        return False
    updated = json.dumps(result, indent=2, sort_keys=True) + "\n"
    for name in changed:
        print(f"{name}: {catalog[name]['version']} -> {result[name]['version']}")
    print("".join(difflib.unified_diff(original.splitlines(True), updated.splitlines(True),
                                    fromfile=str(path), tofile=str(path))), end="")
    if write:
        if path.read_text() != original:
            raise ValueError("Catalog changed during the update; retry without overwriting concurrent edits")
        descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
        try:
            with os.fdopen(descriptor, "w") as output:
                output.write(updated)
                output.flush()
                os.fsync(output.fileno())
            os.chmod(temporary, path.stat().st_mode & 0o777)
            os.replace(temporary, path)
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
        print(f"Updated {path}. Build the changed apps and run the Craft checks before activation.")
    return True

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("apps", nargs="*", help="App names, e.g. filmcraft photocraft")
    parser.add_argument("--all", action="store_true", help="Select the whole pinned suite")
    action = parser.add_mutually_exclusive_group()
    action.add_argument("--check", action="store_true", help="Report updates without writing (default)")
    action.add_argument("--write", action="store_true", help="Update the local catalog atomically")
    parser.add_argument("--version", help="Pin one app to a specific release instead of latest stable")
    parser.add_argument("--catalog", type=Path, default=CATALOG, help="Catalog path; run from nix-config by default")
    args = parser.parse_args()
    if args.version and not re.fullmatch(r"v?[0-9][A-Za-z0-9.+_-]*", args.version):
        parser.error("--version must be a release version, e.g. 0.7.2")
    if args.all and args.apps:
        parser.error("Use app names or --all, not both")
    if args.write and not args.apps and not args.all:
        parser.error("--write requires app names or --all")
    if not args.catalog.is_file():
        parser.error(f"Catalog not found: {args.catalog}; run from nix-config or pass --catalog")
    apps = sorted(set(args.apps)) if args.apps else sorted(json.loads(args.catalog.read_text()))
    try:
        changed = update_catalog(args.catalog, apps, write=args.write, version=args.version)
    except (OSError, ValueError, KeyError) as error:
        parser.exit(2, f"artcraft-update: {error}\n")
    return 1 if changed and not args.write else 0

if __name__ == "__main__":
    raise SystemExit(main())
