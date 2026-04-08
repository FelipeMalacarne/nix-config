# modules/home/desktop/ghostty.nix
{ pkgs, config, ... }:
let
  p = config.colorScheme.palette;
in
{
  home.packages = [ pkgs.nerd-fonts.fira-code ];

  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "FiraCode Nerd Font Mono";
      font-size = 10;

      background-opacity = 0.95;
      window-decoration = false;

      background  = p.base00;
      foreground  = p.base05;
      cursor-color = p.base06;
      selection-background = p.base06;
      selection-foreground = p.base00;

      palette = [
        "0=#${p.base00}"   # black
        "1=#${p.base08}"   # red
        "2=#${p.base0B}"   # green
        "3=#${p.base0A}"   # yellow
        "4=#${p.base0D}"   # blue
        "5=#${p.base0E}"   # magenta
        "6=#${p.base0C}"   # cyan
        "7=#${p.base05}"   # white
        "8=#${p.base03}"   # bright black
        "9=#${p.base08}"   # bright red
        "10=#${p.base0B}"  # bright green
        "11=#${p.base0A}"  # bright yellow
        "12=#${p.base0D}"  # bright blue
        "13=#${p.base0E}"  # bright magenta
        "14=#${p.base0C}"  # bright cyan
        "15=#${p.base07}"  # bright white
      ];
    };

    extraConfig = ''
      keybind = shift+enter=text:\x1b\r
      keybind = ctrl+left=text:\x1bb
      keybind = ctrl+right=text:\x1bf
      keybind = alt+left=text:\x01
      keybind = alt+right=text:\x05
    '';
  };
}
