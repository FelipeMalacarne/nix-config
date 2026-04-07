{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "uwsm app -- alacritty"
      "uwsm app -- noctalia-shell"
    ];
  };
}
