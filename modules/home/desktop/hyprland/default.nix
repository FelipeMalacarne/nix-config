# modules/home/desktop/hyprland/default.nix
#
# UWSM note: programs.hyprland.withUWSM = true is set at the NixOS level.
# Apps launched from Hyprland should use `uwsm app -- <appname>` in exec-once
# and keybinds. See: https://wiki.hyprland.org/Useful-Utilities/Systemd-start/
{ config, pkgs, lib, ... }:
let
  p = config.colorScheme.palette;
in
{
  imports = [
    ./autostart.nix
    ./binds.nix
    ./rules.nix
    ./animations.nix
    ./envs.nix
    ./monitors.nix
    ./input.nix
  ];

  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  # Tells portals and apps that query color-scheme (e.g. Firefox, Electron) to use dark
  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  home.pointerCursor = {
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
    gtk.enable = true;
    x11.enable = true;
  };

  # UWSM launches Hyprland via systemd, so cursor env vars must be in the
  # systemd user session — the hyprland env = [...] block only reaches children.
  systemd.user.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "22";
    SSH_AUTH_SOCK = "$HOME/.bitwarden-ssh-agent.sock";
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(${p.base0E}ff)"; # mauve
        "col.inactive_border" = "rgba(${p.base04}ff)"; # surface2
        layout = "dwindle";
      };

      decoration = {
        rounding = 20;
        rounding_power = 2;

        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        blur = {
          enabled = true;
          size = 3;
          passes = 2;
          vibrancy = 0.1696;
        };
      };

      layerrule = [
        {
          name = "noctalia";
          "match:namespace" = "noctalia-background-.*";
          blur = true;
          ignore_alpha = 0.5;
        }
        {
          name = "noctalia-shell-region";
          "match:namespace" = "noctalia-shell:regionSelector";
          no_anim = true;
        }
      ];

      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };
    };
  };
}
