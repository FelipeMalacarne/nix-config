# modules/features/nvim.nix
#
# Installs neovim built with the active colorScheme palette.
# Colors are injected as NIX_COLOR_BASE00..NIX_COLOR_BASE0F env vars.
# Read them in Lua via vim.fn.getenv("NIX_COLOR_BASE0E") etc.
#
# To update: push to the nvim repo, run `nix flake update nvim-config`, then rebuild.
{
  config,
  inputs,
  pkgs,
  ...
}:
let
  user = config.my.user.name;
in
{
  home-manager.users.${user} =
    { config, ... }:
    {
      home.packages = [
        (inputs.nvim-config.lib.mkPackage pkgs config.colorScheme.palette)
      ];
    };
}
