# modules/presets/base.nix
#
# Base preset — every host gets this: core system, theming, shell,
# identity, editor, CLI tools, and fonts.
{ ... }:
{
  imports = [
    ../features/core.nix
    ../features/theming.nix
    ../features/zsh.nix
    ../features/git.nix
    ../features/ssh.nix
    ../features/nvim.nix
    ../features/cli.nix
    ../features/btop.nix
    ../features/yazi.nix
    ../features/fonts.nix
  ];
}
