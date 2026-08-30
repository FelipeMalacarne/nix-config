{ ... }:
{
  flake.homeModules.hyprlandIdle =
    { lib, pkgs, ... }:
    let
      noctalia = lib.getExe pkgs.noctalia-shell;
      hyprctl = "${pkgs.hyprland}/bin/hyprctl";
    in
    {
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "${noctalia} ipc call lockScreen lock";
            before_sleep_cmd = "${noctalia} ipc call lockScreen lock";
            after_sleep_cmd = "${hyprctl} dispatch dpms on";
          };
          listener = [
            {
              timeout = 180;
              on-timeout = "${noctalia} ipc call lockScreen lock";
            }
            {
              timeout = 240;
              on-timeout = "${hyprctl} dispatch dpms off";
              on-resume = "${hyprctl} dispatch dpms on";
            }
          ];
        };
      };
    };
}
