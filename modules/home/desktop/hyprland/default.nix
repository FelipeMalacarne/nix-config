# modules/home/desktop/hyprland/default.nix
#
# UWSM note: programs.hyprland.withUWSM = true is set at the NixOS level.
# Apps launched from Hyprland should use `uwsm app -- <appname>` in exec-once
# and keybinds. See: https://wiki.hyprland.org/Useful-Utilities/Systemd-start/
{ config, ... }:
let
  p = config.colorScheme.palette;
in
{
  imports = [
    ./binds.nix
    ./rules.nix
    ./animations.nix
    ./envs.nix
    ./monitors.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {

      exec-once = [
        "uwsm app -- alacritty"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border"   = "rgba(${p.base0E}ff)"; # mauve
        "col.inactive_border" = "rgba(${p.base04}ff)"; # surface2
        layout = "dwindle";
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      input = {
        kb_layout = "us";
        kb_variant = "intl";
        follow_mouse = 1;
        touchpad.natural_scroll = false;
      };

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };
    };
  };
}
