# modules/features/zsh.nix
#
# System + home-manager module — sets zsh as default shell
# and configures plugins, history, and prompt (starship).
{ config, pkgs, ... }:
let
  user = config.myConfig.primaryUser;
in
{
  programs.zsh.enable = true;
  users.users.${user}.shell = pkgs.zsh;

  home-manager.users.${user} = {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;

      history = {
        size = 50000;
        save = 50000;
        ignoreDups = true;
        ignoreAllDups = true;
        ignoreSpace = true;
        extended = true;
        share = true;
      };

      # Emit OSC 7 on every directory change so terminals (Alacritty, etc.)
      # can open new windows/tabs in the same directory.
      initContent = ''
        _osc7_cwd() { printf '\e]7;file://%s%s\e\\' "$HOST" "$PWD"; }
        autoload -Uz add-zsh-hook
        add-zsh-hook chpwd _osc7_cwd
        _osc7_cwd
      '';
    };

    programs.starship = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
