# modules/home/common/default.nix
{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [
    inputs.nix-colors.homeManagerModules.default
    ./git.nix
    ./nvim.nix
    ./cli.nix
    ./btop.nix
    ./dev-tools.nix
    ./ssh.nix
    ./claude-code.nix
  ];

  options.desktop.colorScheme = lib.mkOption {
    type = lib.types.str;
    default = "catppuccin-mocha";
    description = "nix-colors scheme name to use system-wide.";
  };

  config = {
    colorScheme = inputs.nix-colors.colorSchemes.${config.desktop.colorScheme};

    home.packages = with pkgs; [
      fastfetch
      zip
      unzip
    ];

    # stateVersion must match or be lower than the system stateVersion
    # See: https://nix-community.github.io/home-manager/options.xhtml#opt-home.stateVersion
    home.stateVersion = "24.11";
  };
}
