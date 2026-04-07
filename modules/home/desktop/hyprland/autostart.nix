{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "uwsm app -- qs -c noctalia-shell"
      "uwsm app -- alacritty"
    ];
  };
}
