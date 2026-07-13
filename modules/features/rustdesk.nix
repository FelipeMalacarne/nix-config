{
  flake.homeModules.rustdesk =
    {
      lib,
      pkgs,
      ...
    }:
    let
      rustdesk = pkgs.rustdesk-flutter;
    in
    {
      home.packages = [
        rustdesk
      ];

      wayland.windowManager.hyprland.settings.exec-once = [
        "uwsm app -- ${lib.getExe rustdesk}"
      ];
    };
}
