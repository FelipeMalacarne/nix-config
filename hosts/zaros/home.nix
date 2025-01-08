{ config, pkgs, ... }:
let
  aliases = {
    ll = "ls -lh";
    nixrebuild = "sudo nixos-rebuild switch --flake $HOME/nix-config#zaros";
  };
in
{
  imports = [
    ../../modules/home/neovim
    ../../modules/home/youtube-music
  ];

  home = {
    username = "felipemalacarne";
    homeDirectory = "/home/felipemalacarne";
    stateVersion = "24.05";

    packages = with pkgs; [
      fish
      neofetch
    ];

    file = {
      # ...
    };

    sessionVariables = {
      EDITOR = "nvim";
    };

  };

  xdg.enable = true;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs.zsh = {
    enable = true;
    shellAliases = aliases;
  };

  programs.bash = {
    enable = true;
    shellAliases = aliases;
  };
}
