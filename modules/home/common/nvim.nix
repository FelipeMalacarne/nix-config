# modules/home/common/nvim.nix
#
# The nvim flake input resolves to a read-only Nix store path.
# The config must NOT write into ~/.config/nvim — lazy.nvim writes
# its cache/state to ~/.local/share/nvim and ~/.cache/nvim by default,
# which is correct. Verify the upstream config does not override these paths.
{ inputs, ... }:
{
  home.file.".config/nvim".source = inputs.nvim-config;
}
