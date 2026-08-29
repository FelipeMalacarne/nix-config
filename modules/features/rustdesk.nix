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

      wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''
        hl.on("hyprland.start", function() hl.exec_cmd(${builtins.toJSON "uwsm app -- ${lib.getExe rustdesk}"}) end)
      '';
    };
}
