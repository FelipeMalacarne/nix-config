let
  module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      user = config.my.user.name;
      rustdesk = pkgs.rustdesk-flutter;
    in
    {
      home-manager.users.${user} = {
        home.packages = [
          rustdesk
        ];

        wayland.windowManager.hyprland.settings.exec-once = [
          "uwsm app -- ${lib.getExe rustdesk}"
        ];
      };
    };
in
{
  flake.nixosModules.rustdesk = module;
}
