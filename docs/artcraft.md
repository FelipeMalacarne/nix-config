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
The OpenCode feature supplies that registration automatically when used on a
host with selected Craft apps; other clients still need their own connection.

Installing a package starts no GUI or server. OpenCode starts each selected
CLI's headless MCP when connecting. The agent saves an editable revision;
the user opens that file in the ordinary desktop app. No bridge launchers,
control port or X11/Wayland environment override are configured.

Library/project directories and model downloads remain managed by the
app/user; Nix does not replace existing state. MCP access is not a filesystem
sandbox, so work only within the editing project and explicitly named sources.

### OpenCode integration

When both the Home Manager `opencode` feature and selected `my.artcraft` apps
are present, the configuration derives one local `craft-<app>` MCP server per
enabled app from the host's actual package. Disabled apps are not registered.
Without the ArtCraft feature (including standalone HM and Darwin), OpenCode
keeps its existing configuration and does not gain Craft servers or the editor.

The pieces have distinct roles:

- **MCP** performs editing operations through the selected app's CLI.
- **`artcraft-editing` skill** supplies the inspect, rough-cut, save and verify
  workflow; it is loaded on demand, not injected as a large global prompt.
- **`craft-editor` subagent** exposes Craft tools only for editing tasks. The
  usual coding agents have `craft-*` tools disabled to avoid cluttering their
  tool catalogs. This is tool visibility, not a security sandbox.

The editor inherits OpenCode's normal model choice and permissions. It does
not configure an API provider, subscription, cloud upload or synthetic voice.
Enabling more apps adds their MCP connections to the editor, not to coding
agents; large upstream tool catalogs may still consume the editor's context.

Invoke it explicitly, for example:

```text
@craft-editor Use the footage in ~/Videos/OBS to create a footage log and a
short rough-cut preview. Preserve the source files, keep game and microphone
audio separate, and save an editable project under this workspace's outputs/.
```

After applying the configuration, `opencode mcp list` lists the registered
connections. Existing Playwright registration is preserved. OpenCode's existing
external-directory permissions still apply; access to recordings outside the
workspace may require approval. Do not broadly allow the whole home directory
just to avoid that prompt.

Executable paths use Nix store references rather than assuming commands on PATH:

```nix
command = lib.getExe' app.package "${name}-cli";
args = [ "mcp" ];
```

`lib.getExe app.package` would launch the GUI (`meta.mainProgram`), so `getExe'`
is intentional here. Package overrides and updated pins automatically change
the generated command path. Overrides must still provide `<app>-cli` with the
`mcp` interface. No store hash, user profile path or executable search is
hardcoded.

The suite default is **headless**, not a live bridge to a GUI. For that mode,
open/save explicitly and open/reload the saved revision in the GUI. Never assume
a reconnect preserves state or edit the same file from two engine sessions.

Zaros now selects **headless FilmCraft editing with saved-file handoff**:

```nix
my.artcraft.filmcraft.enable = true;
```

The single `craft-filmcraft` server runs the package's CLI with `mcp`, just like
the other selected apps. There is no per-app mode selector or GUI dependency.
After applying a configuration/package change, reconnect/restart OpenCode;
changing the checkout does not replace an already-running MCP process.

The editor opens/creates the intended input, inspects it, edits a small approved
batch and saves a new `.fcproj`, preview and cue sheet. The user opens that file
with ordinary `filmcraft` (or File > Open in an existing window). The window does
not follow the headless session live. Preserve previous revisions and never let
GUI and agent overwrite the same file concurrently. Manual edits are saved to
a separate input file; the agent explicitly reloads that input for the next cut.

The vault documents this workflow in `docs/filmcraft-collaboration.md`. Start
ordinary `opencode`; no project-specific launcher is required. The retired
bridge experiment is recorded in the vault archive, not maintained as a second
integration path in this module. No feature starts/closes the GUI or activates NixOS.

Validate the integration (selection, overrides, tool scoping and generated HM
JSON) without activating the host:

```sh
nix build 'path:.#checks.x86_64-linux.opencode-craft' --no-link -L
```

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
