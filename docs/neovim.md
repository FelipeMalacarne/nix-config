# Neovim variants

The Home Manager `neovim` feature installs one editor selected by
`my.neovim.variant` (`minimal`, `full`, or `dev`). Its default is minimal; the
`development` profile selects full with `mkDefault`, so hosts can override it.
Saradomin and saradomin-vm use minimal; zaros and macbook use full.

For local configuration development, set these Home Manager options:

```nix
my.neovim = {
  variant = "dev";
  devConfigDir = "${config.home.homeDirectory}/repos/nix-config/modules/features/programs/neovim";
};
```

`devConfigDir` must be an absolute string, not a Nix path literal (which would
copy the checkout into the store). The configured dev wrapper reads this path
directly; it does not need or modify `NVIM_CONFIG_DIR` in the login environment.
The directory must contain `init.lua` when the editor launches. For a custom
package, `my.neovim.package` remains an override of the variant's default.

- `neovim-minimal`: shared editing options, keymaps, terminal window, diagnostics
  UI, Catppuccin theme, Which-key, Neo-tree, Telescope with native FZF, Snacks,
  and Blink completion from LSPs, buffers, paths and snippets. Includes ripgrep/fd
  for file search and live grep, plus Nix (`nil`), Lua (`lua-language-server`) and
  Bash (`bash-language-server`) LSPs. No bundled formatters, external TUIs or
  Python/Node/Ruby remote-plugin providers (the Bash LSP itself uses Node).
  Folding uses indentation instead of Treesitter. Neovim's own built-in parsers
  remain.
- `neovim-full`: workstation plugins, LSPs, formatters and TUIs, with a curated
  Treesitter grammar list rather than all grammars.
- `neovim`: compatibility alias for `neovim-full`.
- `neovim-dev`: full dependencies, but reads Lua from `NVIM_CONFIG_DIR` on launch.
  It requires an absolute directory containing `init.lua` and has no fallback to
  an unrelated user config. Normal packages always use the immutable store copy.

## Shared controls

The leader key is Space. Both minimal and full provide:

| Key | Action |
| --- | --- |
| `<leader>ff` / `<leader><leader>` | Find files |
| `<leader>fg` | Search file contents (live grep) |
| `<leader>fb` | Switch buffers |
| `<leader>fr` | Recent files |
| `<leader>/` | Fuzzy search current buffer |
| `<leader>e` / `<leader>E` | File explorer / current file's directory |
| `<leader>?` | Show key hints |
| `<C-/>` | Toggle terminal |
| `<C-Space>` | Show completion |

Both provide LSP completion, hover (`K`), definitions (`gd`), rename (`<leader>rn`)
and code actions (`<leader>ca`) when a supported server attaches. Telescope symbol
search uses `<leader>fs` / `<leader>fw`. Full adds the wider language-server suite
(including PHPantom and nixd rather than nil), formatting and external TUIs.

## Standalone packages

From the repository root:

```sh
nix run 'path:.#neovim-minimal' -- /path/to/file
nix run 'path:.#neovim-full' -- /path/to/file
NVIM_CONFIG_DIR="$PWD/modules/features/programs/neovim" nix run 'path:.#neovim-dev'
```

GitHub runs use the published revision, independently of Home Manager settings.
If a recently published update seems missing, refresh Nix's flake cache:

```sh
nix run --refresh github:FelipeMalacarne/nix-config#neovim-minimal
```

Restart the dev editor to pick up Lua edits without rebuilding. Plugin, grammar,
LSP or other Nix dependency changes still require a rebuild. This is not live
reloading of an already-running editor.

The package factory and server/executable manifest live in
`modules/features/programs/neovim/config/packages.nix`. Lua loads full plugin
configuration explicitly and enables only the servers in that manifest.
Intelephense (disabled), Texlab (not bundled), and unused SQLfluff/Dockerfmt
dependencies are not included. PHP formatting still uses project-provided
`pint`; it is not bundled by this configuration.

`checks.<system>.neovim` tests headless minimal, full and dev startup, core
keymaps, theme, variant isolation, LSP executable availability and representative
Treesitter parsers. Minimal also tests real Nix/Lua/Bash server initialization,
completion support and buffer keymaps. It does not activate host configurations.
`checks.<system>.neovim-selection` verifies all four hosts select the expected
package and that the compatibility alias points to full.
`checks.<system>.neovim-options` verifies variant selection, custom package
overrides, the required dev path and startup using a configured dev directory
even when the shell supplies a different `NVIM_CONFIG_DIR`.
