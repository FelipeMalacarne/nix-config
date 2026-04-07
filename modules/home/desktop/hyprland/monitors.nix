{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "DP-1, 2560x1440@240, auto, 1"
      "HDMI-A-1, 2560x1440@75, -1080x-300, 1, transform, 1"
    ];

    workspace = [
      "1, monitor:DP-1"
      "2, monitor:DP-1"
      "3, monitor:DP-1"
      "4, monitor:DP-1"
      "5, monitor:DP-1"
      "6, monitor:HDMI-A-1"
      "7, monitor:HDMI-A-1"
    ];
  };
}
