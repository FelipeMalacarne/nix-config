# modules/home/desktop/hyprland/default.nix
#
# UWSM note: programs.hyprland.withUWSM = true is set at the NixOS level.
# Apps launched from Hyprland should use `uwsm app -- <appname>` in exec-once
# and keybinds. See: https://wiki.hyprland.org/Useful-Utilities/Systemd-start/
{ ... }:
{
  imports = [
    ./binds.nix
    ./rules.nix
    ./animations.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = ",preferred,auto,1"; # auto-detect monitor

      exec-once = [
        "uwsm app -- ghostty" # spawn a terminal on start
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(cba6f7ff)"; # Catppuccin Mocha mauve
        "col.inactive_border" = "rgba(6c7086ff)"; # Catppuccin Mocha overlay0
        layout = "dwindle";
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      input = {
        kb_layout = "br"; # Brazilian ABNT2 keyboard
        follow_mouse = 1;
        touchpad.natural_scroll = false;
      };

      misc = {
        force_default_wallpaper = 0; # disable Hyprland anime wallpaper
        disable_hyprland_logo = true;
      };
    };
  };
}
