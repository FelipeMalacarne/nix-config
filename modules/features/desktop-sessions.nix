{ ... }:
{
  flake.nixosModules.desktopSessions =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      i3Session = pkgs.writeTextFile {
        name = "i3-session";
        destination = "/share/xsessions/i3.desktop";
        text = ''
          [Desktop Entry]
          Name=i3
          Comment=improved dynamic tiling window manager
          Exec=i3
          TryExec=i3
          Type=XSession
        '';
        passthru.providedSessions = [ "i3" ];
      };
      hyprlandUwsmSession = pkgs.writeTextFile {
        name = "hyprland-uwsm-session";
        destination = "/share/wayland-sessions/hyprland-uwsm.desktop";
        text = ''
          [Desktop Entry]
          Name=Hyprland (UWSM)
          Comment=Hyprland compositor managed by UWSM
          Exec=${lib.getExe pkgs.uwsm} start -F -- ${lib.getExe config.programs.hyprland.package}
          Type=Application
        '';
        passthru.providedSessions = [ "hyprland-uwsm" ];
      };
    in
    {
      services.displayManager.sessionPackages = lib.mkForce [
        i3Session
        hyprlandUwsmSession
      ];
    };
}
