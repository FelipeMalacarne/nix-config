# modules/features/ghostty.nix
#
# Home-manager module — imported inside home-manager.users.<user>.imports
# on each host (works cross-platform with different usernames).
{ lib, pkgs, config, ... }:
let
  p = config.colorScheme.palette;
  ghosttySettings = {
    font-family = "FiraCode Nerd Font Mono";
    font-size = 12;
    background-opacity = 0.95;
    window-decoration = false;
    confirm-close-surface = false;

    background = p.base00;
    foreground = p.base05;
    cursor-color = p.base06;
    selection-background = p.base06;
    selection-foreground = p.base00;

    palette = [
      "0=#${p.base00}"
      "1=#${p.base08}"
      "2=#${p.base0B}"
      "3=#${p.base0A}"
      "4=#${p.base0D}"
      "5=#${p.base0E}"
      "6=#${p.base0C}"
      "7=#${p.base05}"
      "8=#${p.base03}"
      "9=#${p.base08}"
      "10=#${p.base0B}"
      "11=#${p.base0A}"
      "12=#${p.base0D}"
      "13=#${p.base0E}"
      "14=#${p.base0C}"
      "15=#${p.base07}"
    ];
    keybind = [
      "shift+enter=text:\\x1b\\r"
      "ctrl+left=text:\\x1bb"
      "ctrl+right=text:\\x1bf"
      "alt+left=text:\\x01"
      "alt+right=text:\\x05"
    ];
  };
in
{
  home.packages = [ pkgs.nerd-fonts.fira-code ];
  home.sessionVariables.TERMINAL = "ghostty";

  # On Linux: install package + write config via home-manager module
  programs.ghostty = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    settings = ghosttySettings;
  };

  # On macOS: ghostty is installed externally (Homebrew); just write the config
  xdg.configFile."ghostty/config" = lib.mkIf pkgs.stdenv.isDarwin {
    text = lib.generators.toKeyValue {
      listsAsDuplicateKeys = true;
    } ghosttySettings;
  };
}
