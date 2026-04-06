# modules/home/common/nvim.nix
#
# Installs the wrapped nvim package from the nvim-config flake.
# It bundles neovim + all LSPs/formatters/tools and manages its own config dir.
# To update: push to the nvim repo, run `nix flake update nvim-config`, then rebuild.
{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.nvim-config.packages.${pkgs.system}.default
  ];
}
