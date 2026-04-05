# modules/home/common/nvim.nix
#
# The nvim flake input resolves to a read-only Nix store path.
# Lazy.nvim writes plugins/state to ~/.local/share/nvim and ~/.cache/nvim — unchanged.
# To update: push to the nvim repo, run `nix flake update nvim-config`, then rebuild.
{ inputs, ... }:
{
  home.file.".config/nvim".source = inputs.nvim-config;
}
