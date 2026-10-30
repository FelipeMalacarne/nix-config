# Craft applications

The ArtCraft suite is packaged in the
[`artcraft-flake`](https://github.com/FelipeMalacarne/artcraft-flake) input,
which owns the binaries, release pins, updater and package/CLI/MCP checks.
Its README lists the available apps and options. This repository only selects
apps and wires the OpenCode editor.

## Selection

`modules/features/applications/artcraft.nix` registers the upstream Home
Manager module as the `artcraft` aspect. Importing it installs nothing; select
apps through the native `programs.artcraft` options:

```nix
home-manager.users.${user} = {
  imports = with self.modules.homeManager; [ artcraft ];

  programs.artcraft = {
    apps.filmcraft.enable = true;
    mcp.enable = true;
  };
};
```

Zaros selects **FilmCraft only**, with MCP registration. Every
`apps.<app>.enable` is independent, and `apps.<app>.package` overrides a
package (it must still provide `<app>-cli`).

`mcp.enable` registers `craft-<app>` for each selected app in the shared
`programs.mcp.servers` registry, so both OpenCode and Claude Code pick them up.
Each server runs the selected package's `<app>-cli mcp` headlessly. No feature
starts a GUI, control port or background service.

## OpenCode editor

When the ArtCraft module is imported, `mcp.enable` is set and at least one app
is selected, the OpenCode feature also adds:

- **`craft-editor` subagent** with the `craft-*` tools enabled. Ordinary coding
  agents have `craft-*` disabled to keep their tool catalogs small. This is
  tool visibility, not a security sandbox.
- **`artcraft-editing` skill**, loaded on demand, with the inspect, rough-cut,
  save and verify workflow.

Without that selection (including standalone HM and Darwin), OpenCode gains no
Craft agent or skill. The editor inherits OpenCode's normal model and
permissions and configures no provider, cloud upload or synthetic voice.

Invoke it explicitly, for example:

```text
@craft-editor Use the footage in ~/Videos/OBS to create a footage log and a
short rough-cut preview. Preserve the source files, keep game and microphone
audio separate, and save an editable project under this workspace's outputs/.
```

Headless MCP is not a live bridge to a GUI window. The editor opens or creates
the intended input, edits a small approved batch, and saves a new revision
(for FilmCraft, a `.fcproj`, preview and cue sheet). The user opens that file
in the ordinary desktop app. Preserve previous revisions, and never let the GUI
and the agent overwrite the same file at the same time. Manual edits go into a
separate input file, which the agent explicitly reloads for the next cut. After
changing packages or configuration, restart OpenCode; a running MCP process is
not replaced. OpenCode's external-directory permissions still apply. Do not
allow the whole home directory just to avoid an approval prompt.

The vault documents this workflow in `docs/filmcraft-collaboration.md`.

## Updating

The flake's scheduled GitHub Action pins new stable releases after its full
check matrix passes. Pick them up and validate without activating:

```sh
nix flake update artcraft
nix build '.#checks.x86_64-linux.opencode-craft' --no-link -L
make eval-check
make build HOST=zaros
```

To pin or roll back one app, use the flake's updater in its own checkout
(`nix run .#artcraft-update -- filmcraft --version 0.7.2 --write`), or lock
the input to an earlier revision. A successful build does not establish GUI,
GPU or audio-device compatibility. Native GUI checks follow this repository's
approval policy.
