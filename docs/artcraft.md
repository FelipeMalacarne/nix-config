# Craft applications on NixOS

Import the suite feature and select apps individually:

```nix
imports = [ self.modules.nixos.artcraft ];

my.artcraft = {
  filmcraft.enable = true;
  photocraft.enable = true;
  effectcraft.enable = false;
};
```

All flags default to false. Importing the feature alone installs nothing.
Zaros currently selects only FilmCraft. No desktop profile imports the suite.

## Available apps

Set the corresponding flag to `true` in your host configuration to install an
app. Every row is independent; enabling FilmCraft does not enable the other apps.
Purposes below follow the [official Craft catalog](https://getartcraft.com/apps).

| App | Use | Enable option |
| --- | --- | --- |
| [PhotoCraft](https://getartcraft.com/apps/photocraft) | Image editing; thumbnail artwork | `my.artcraft.photocraft.enable` |
| [VectorCraft](https://getartcraft.com/apps/vectorcraft) | Vector illustration; logos and diagrams | `my.artcraft.vectorcraft.enable` |
| [FilmCraft](https://getartcraft.com/apps/filmcraft) | Video editing; gameplay timelines | `my.artcraft.filmcraft.enable` |
| [LightCraft](https://getartcraft.com/apps/lightcraft) | Photo library and RAW development | `my.artcraft.lightcraft.enable` |
| [PdfCraft](https://getartcraft.com/apps/pdfcraft) | Read, organize, combine and split PDFs | `my.artcraft.pdfcraft.enable` |
| [EffectCraft](https://getartcraft.com/apps/effectcraft) | Motion graphics and visual effects | `my.artcraft.effectcraft.enable` |
| [DesignCraft](https://getartcraft.com/apps/designcraft) | Page layout and publishing | `my.artcraft.designcraft.enable` |
| [FigCraft](https://getartcraft.com/apps/figcraft) | Interface design and prototyping | `my.artcraft.figcraft.enable` |
| [WordCraft](https://getartcraft.com/apps/wordcraft) | Word processing and documents | `my.artcraft.wordcraft.enable` |
| [SoundCraft](https://getartcraft.com/apps/soundcraft) | Audio recording, editing and mixing | `my.artcraft.soundcraft.enable` |
| [DeckCraft](https://getartcraft.com/apps/deckcraft) | Presentations and slides | `my.artcraft.deckcraft.enable` |
| [CADCraft](https://getartcraft.com/apps/cadcraft) | CAD drawing and drafting | `my.artcraft.cadcraft.enable` |
| [GridCraft](https://getartcraft.com/apps/gridcraft) | Spreadsheets and data analysis | `my.artcraft.gridcraft.enable` |

For example, start with video editing and thumbnail tools; leave additional
motion graphics and audio tools disabled until needed:

```nix
# In hosts/zaros/default.nix, after importing self.modules.nixos.artcraft:
my.artcraft = {
  filmcraft.enable = true;
  photocraft.enable = true;
  effectcraft.enable = false;
  soundcraft.enable = false;
};
```

This is an example, not the active selection: Zaros currently enables FilmCraft
only. Omitted flags remain `false`. Each selected package includes its desktop
app, CLI and headless MCP launcher; it does not start them automatically.

The lowercase identifier in the option is also the flake package name and the
Makefile `APPS` value, for example `nix run 'path:.#photocraft'` and
`make artcraft-update APPS=photocraft`. `APPS` selects catalog entries to update;
it does not enable or install apps in the host.

Versions and SHA-256 hashes are pinned in
[`releases.json`](../modules/features/applications/artcraft/config/releases.json),
which is the source of truth for the packaged apps. Linux x86_64 and ARM64
tarballs are cataloged; ARM64 is not runtime-tested on Zaros, and Darwin desktop
packages are not exposed.

## Package overrides and standalone use

Each app also has a package override, for example:

```nix
my.artcraft.filmcraft.package = self.packages.${pkgs.stdenv.hostPlatform.system}.filmcraft;
```

Packages are available independently of host selection:

```sh
nix run 'path:.#filmcraft'
nix shell 'path:.#filmcraft' --command filmcraft-cli --help
nix build 'path:.#photocraft' --no-link
nix build 'path:.#checks.x86_64-linux.artcraft-selection' --no-link
nix build 'path:.#checks.x86_64-linux.artcraft-cli' --no-link -L
```

## Files

- `modules/features/applications/artcraft/artcraft.nix`: public options and flake packages.
- `config/packages.nix`: shared binary packaging, runtime libraries and launchers.
- `config/releases.json`: per-app version, source URLs, SHA-256 and release link.
- `config/test-selection.nix`: default-off, independent selection and override checks.
- `config/test-cli.py`: CLI execution and MCP initialization/tool-list checks for every app.
- `config/update-releases.py`: explicit release refresh with atomic catalog writes.
- `config/test-update.py`: offline updater regression checks.

## Agent access

Every selected package includes the desktop app, `<app>-cli` and
`<app>-mcp-headless`. The last command starts `<app>-cli mcp` over stdio.
Registering an MCP connection is separate from installing a package.

FilmCraft retains `filmcraft-agent` (window with loopback control on port 9876)
and `filmcraft-mcp` (MCP bridge to that window). Other apps' live-window flags
differ; use their release-specific docs instead of assuming the FilmCraft flags.

No server or GUI starts automatically. Library/project directories and model
downloads remain managed by the app/user; Nix does not replace existing state.
Some upstream MCP servers expose unrestricted filesystem access, so connection
scope should match the editing project.

## Updating

Versions are pinned independently in `config/releases.json`; `nix flake update`
does not change them. Run the updater from the repository root:

```sh
make artcraft-updates                          # Check the whole suite
make artcraft-updates APPS=filmcraft            # Check one app
make artcraft-update                           # Refresh the whole suite
make artcraft-update APPS="filmcraft photocraft"
make artcraft-update APPS=filmcraft VERSION=0.7.2
make artcraft-check                            # Build/test the suite on Linux
```

`APPS` defaults to `all`; `VERSION` is optional and requires exactly one app.
`artcraft-updates` writes nothing. Like the underlying CLI, it exits nonzero if
updates are available, so Make reports an error status in that case. Inspect
the diff to distinguish available updates from a failed request. `artcraft-check`
runs selection, CLI/MCP and updater tests on Linux; it runs updater tests only on
Darwin, where the desktop packages are not provided. No target activates NixOS.

The equivalent direct CLI commands are:

```sh
# Check all apps. Exit 0 = up to date, 1 = updates available, 2 = error.
nix run 'path:.#artcraft-update' -- --check

# Refresh a single app, multiple apps, or the whole suite.
nix run 'path:.#artcraft-update' -- filmcraft --write
nix run 'path:.#artcraft-update' -- filmcraft photocraft --write
nix run 'path:.#artcraft-update' -- --all --write

# Pin a specific release when needed, including rolling back a problematic update.
nix run 'path:.#artcraft-update' -- filmcraft --version 0.7.2 --write
```

The default is check-only. `--write` requires app names or `--all`. The updater
queries published stable releases, selects exact app tarballs (not similarly named
CLI/server assets), and retrieves official SHA-256 values for every architecture
already in the catalog. GitHub API rate limits fall back to the public latest
release redirect and `SHA256SUMS.txt`; `GITHUB_TOKEN` is optional for API requests.

It prints the diff, fetches all selected apps before writing, and replaces the
catalog atomically. Missing assets/checksums abort the whole batch. It refuses to
overwrite a catalog changed while releases were being fetched. `--catalog PATH`
supports a separate checkout or preview catalog. Updating does not build, activate,
commit, change app selections, or register MCP connections.

After updating, inspect the diff and validate the affected app and host:

```sh
nix build 'path:.#filmcraft' --no-link
nix build 'path:.#checks.x86_64-linux.artcraft-selection' \
  'path:.#checks.x86_64-linux.artcraft-cli' \
  'path:.#checks.x86_64-linux.artcraft-updater' --no-link -L
make eval-check
make build HOST=zaros
```

Only the explicit updater contacts `latest`; Nix builds always consume pinned
URLs and verify their hashes. Previous catalog entries can be restored through
Git or selected with `--version`. The updater package and offline tests are also
available on Darwin; the creative app packages remain Linux-only.

The suite is young. A successful binary build does not establish GUI, GPU,
audio-device or every document-format compatibility. Native GUI/GPU checks
follow the repository's approval policy.

Validation on Zaros (x86_64 Linux): all 13 pinned packages build, the selection
check passes, and each packaged CLI reports its version and completes an MCP
handshake with a nonempty tool catalog. LightCraft is tested with `--demo` to
avoid creating a normal photo library. These checks open no graphical windows.

Official catalog: https://getartcraft.com/apps
