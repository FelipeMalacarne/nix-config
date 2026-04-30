# modules/features/hyprland/rules.nix
{ ... }:
{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      {
        name = "bitwarden-workspace";
        workspace = "5 silent";
        "match:class" = "^(Bitwarden)$";
      }
    ];
  };
}
