# modules/home/common/nvim.nix
#
# Installs the nvim package built with the active colorScheme palette.
# Colors are injected as NIX_COLOR_BASE00..NIX_COLOR_BASE0F env vars into the
# wrapper — read them in Lua via vim.fn.getenv("NIX_COLOR_BASE0E") etc.
#
# Standalone usage:  nix run github:FelipeMalacarne/nvim  (uses catppuccin-mocha)
# From nix-config:   lib.mkPackage passes the active nix-colors palette
#
# To update: push to the nvim repo, run `nix flake update nvim-config`, then rebuild.
{
  inputs,
  pkgs,
  config,
  ...
}:
{
  home.packages = [
    (inputs.nvim-config.lib.mkPackage pkgs config.colorScheme.palette)
  ];
}
