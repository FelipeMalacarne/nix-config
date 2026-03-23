# modules/home/desktop/hyprland/rules.nix
# Minimal stub — add window rules as needed
{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    windowrulev2 = [
      # example: "float, class:^(pavucontrol)$"
    ];
  };
}
