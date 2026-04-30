# modules/features/hyprland/idle.nix
#
# Hypridle: lock after 3 min, DPMS off after 4 min.
{ ... }:
{
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "noctalia-shell ipc call lockScreen lock";
        before_sleep_cmd = "noctalia-shell ipc call lockScreen lock";
        after_sleep_cmd = "/run/current-system/sw/bin/hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 180;
          on-timeout = "noctalia-shell ipc call lockScreen lock";
        }
        {
          timeout = 240;
          on-timeout = "/run/current-system/sw/bin/hyprctl dispatch dpms off";
          on-resume = "/run/current-system/sw/bin/hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
