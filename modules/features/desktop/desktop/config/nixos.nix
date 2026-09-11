{ config, lib, ... }:
{
  config = {
    home-manager.users.${config.my.user.name} = {
      my.desktop.sessions = config.my.desktop.sessions;
      my.desktop.shell = config.my.desktop.shell;
      my.desktop.monitors = config.my.desktop.monitors;
    };
    hardware.bluetooth.enable = lib.mkIf (builtins.elem "hyprland" config.my.desktop.sessions) true;
    services.power-profiles-daemon.enable = lib.mkIf (builtins.elem "hyprland" config.my.desktop.sessions) true;
    services.upower.enable = lib.mkIf (builtins.elem "hyprland" config.my.desktop.sessions) true;
  };
}
