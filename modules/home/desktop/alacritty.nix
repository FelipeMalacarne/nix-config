# modules/home/desktop/alacritty.nix
{ pkgs, config, ... }:
let
  p = config.colorScheme.palette;
in
{
  home.packages = [ pkgs.nerd-fonts.fira-code ];

  programs.alacritty = {
    enable = true;
    settings = {
      env.TERM = "xterm-256color";

      window = {
        decorations = "None";
        opacity = 0.95;
      };

      font = {
        normal = {
          family = "FiraCode Nerd Font Mono";
          style = "Regular";
        };
        size = 10.0;
      };

      colors = {
        primary = {
          background = "#${p.base00}";
          foreground = "#${p.base05}";
        };
        cursor = {
          text = "#${p.base00}";
          cursor = "#${p.base06}"; # rosewater
        };
        selection = {
          text = "#${p.base00}";
          background = "#${p.base06}";
        };
        normal = {
          black = "#${p.base00}";
          red = "#${p.base08}";
          green = "#${p.base0B}";
          yellow = "#${p.base0A}";
          blue = "#${p.base0D}";
          magenta = "#${p.base0E}";
          cyan = "#${p.base0C}";
          white = "#${p.base05}";
        };
        bright = {
          black = "#${p.base03}";
          red = "#${p.base08}";
          green = "#${p.base0B}";
          yellow = "#${p.base0A}";
          blue = "#${p.base0D}";
          magenta = "#${p.base0E}";
          cyan = "#${p.base0C}";
          white = "#${p.base07}";
        };
      };

      keyboard.bindings = [
        {
          key = "Return";
          mods = "Shift";
          chars = "\\u001B\\r";
        }

        # word jumping (Control+Arrow)
        {
          key = "Left";
          mods = "Control";
          chars = "\\u001Bb";
        } # backward-word
        {
          key = "Right";
          mods = "Control";
          chars = "\\u001Bf";
        } # forward-word

        # line start/end (Alt+Arrow)
        {
          key = "Left";
          mods = "Alt";
          chars = "\\u0001";
        } # Alt+A / beginning-of-line
        {
          key = "Right";
          mods = "Alt";
          chars = "\\u0005";
        } # ALt+E / end-of-line
      ];
    };
  };
}
