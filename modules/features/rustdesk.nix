let
  module =
    { config, lib, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user} = {
        home.packages = [ pkgs.rustdesk ];

        wayland.windowManager.hyprland.settings.exec-once = [
          "uwsm app -- ${lib.getExe pkgs.rustdesk}"
        ];
      };
    };
in
{
  flake.nixosModules.rustdesk = module;
}
