{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "uwsm app -- noctalia-shell"
      "uwsm app -- alacritty"
    ];
  };
}
