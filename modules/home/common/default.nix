# modules/home/common/default.nix
{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.nix-colors.homeManagerModules.default
    ./git.nix
    ./zsh.nix
    ./nvim.nix
    ./cli.nix
    ./btop.nix
    ./dev-tools.nix
  ];

  # Default theme — override per-host by setting colorScheme in the host file
  colorScheme = lib.mkDefault inputs.nix-colors.colorSchemes.catppuccin-mocha;
  # colorScheme = lib.mkDefault inputs.nix-colors.colorSchemes.gruvbox-dark-hard;

  home.packages = with pkgs; [
    fastfetch
  ];

  # stateVersion must match or be lower than the system stateVersion
  # See: https://nix-community.github.io/home-manager/options.xhtml#opt-home.stateVersion
  home.stateVersion = "24.11";
}
