# modules/features/cli.nix
#
# General-purpose CLI tools: search, navigation, and base utilities.
{ config, pkgs, ... }:
let
  user = config.myConfig.primaryUser;
in
{
  home-manager.users.${user} = {
    home.packages = with pkgs; [
      ripgrep
      fd
      jq
      bat
      fastfetch
      zip
      unzip
      p7zip-rar
    ];

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.eza = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
