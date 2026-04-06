# modules/home/desktop/ghostty.nix
{ config, ... }:
let
  p = config.colorScheme.palette;
in
{
  programs.ghostty = {
    enable = true;
    settings = {
      font-size = 13;
      shell-integration = "zsh";
      window-decoration = false; # Hyprland handles decorations
      background-opacity = 0.95;

      background          = p.base00;
      foreground          = p.base05;
      cursor-color        = p.base06; # rosewater
      selection-background = p.base02;
      selection-foreground = p.base05;
    };
  };
}
