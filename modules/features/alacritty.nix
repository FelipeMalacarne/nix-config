# modules/features/alacritty.nix
{ pkgs, config, ... }:
let
  user = config.my.user.name;
in
{
  home-manager.users.${user} =
    { config, ... }:
    let
      p = config.colorScheme.palette;
    in
    {
      home.packages = [ pkgs.nerd-fonts.fira-code ];
      home.sessionVariables.TERMINAL = "alacritty";

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
            size = 12.0;
          };

          colors = {
            primary = {
              background = "#${p.base00}";
              foreground = "#${p.base05}";
            };
            cursor = {
              text = "#${p.base00}";
              cursor = "#${p.base06}";
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
            {
              key = "Left";
              mods = "Control";
              chars = "\\u001Bb";
            }
            {
              key = "Right";
              mods = "Control";
              chars = "\\u001Bf";
            }
            {
              key = "Left";
              mods = "Alt";
              chars = "\\u0001";
            }
            {
              key = "Right";
              mods = "Alt";
              chars = "\\u0005";
            }
          ];
        };
      };
    };
}
