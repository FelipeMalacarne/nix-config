{
  config,
  lib,
  pkgs,
  ...
}:
let
  wayland = lib.any (session: builtins.elem session config.my.desktop.sessions) [
    "hyprland"
    "umbriel"
  ];
in
{
  config = {
    home-manager.users.${config.my.user.name} = {
      my.desktop.sessions = config.my.desktop.sessions;
      my.desktop.defaultSession = config.my.desktop.defaultSession;
      my.desktop.shell = config.my.desktop.shell;
      my.desktop.monitors = config.my.desktop.monitors;
    };
    hardware.bluetooth.enable = lib.mkIf wayland true;
    services.power-profiles-daemon.enable = lib.mkIf wayland true;
    services.upower.enable = lib.mkIf wayland true;
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      # Native compositor portals override this safe cross-session fallback.
      config.common.default = lib.mkDefault [ "gtk" ];
    };
  };
}
