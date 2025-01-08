{ config, pkgs, ... }:
let
  aliases = {
    ll = "ls -lh";
    nixrebuild = "sudo nixos-rebuild switch --flake $HOME/nix-config#zaros";
  };
in
{
  home.username = "felipemalacarne";
  home.homeDirectory = "/home/felipemalacarne";

  xdg.enable = true;

  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    fish
    neofetch
    youtube-music
  ];

  home.file = {
    ".config/YouTube Music/" = {
        source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/config/YouTube Music";
        recursive = true;
    };
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/felipem/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
     EDITOR = "nvim";
  };

  imports = [
   ../../modules/home/neovim 
  ];

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
