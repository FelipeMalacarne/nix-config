# modules/home/common/nvim.nix
#
# Manages the nvim config as a live git repo rather than a read-only store symlink.
# This lets you edit ~/.config/nvim directly, run :Lazy update, use Mason, etc.
# On first activation: clones the repo. On subsequent activations: leaves it alone.
# To update: git pull inside ~/.config/nvim, or push changes from there.
{ pkgs, lib, config, ... }:
{
  home.activation.cloneNvimConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -d "${config.home.homeDirectory}/.config/nvim/.git" ]; then
      ${pkgs.git}/bin/git clone https://github.com/FelipeMalacarne/nvim \
        "${config.home.homeDirectory}/.config/nvim"
    fi
  '';
}
