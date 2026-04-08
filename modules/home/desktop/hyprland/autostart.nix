{ config, ... }:
{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      config.desktop.terminal.exec
      "uwsm app -- noctalia-shell"
    ];
  };
}
