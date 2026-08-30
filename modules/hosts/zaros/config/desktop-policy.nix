{ ... }:
{
  flake.nixosModules.zarosDesktopPolicy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      user = config.my.user.name;
      i3Session = pkgs.i3.overrideAttrs (old: {
        passthru = (old.passthru or { }) // {
          providedSessions = [ "i3" ];
        };
      });
      hyprlandUwsmSession = pkgs.writeTextFile {
        name = "hyprland-uwsm";
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
      home-manager.users.${user}.my.displayTopology.outputs = config.my.displayTopology.outputs;
      my.displayTopology.outputs = {
        main = {
          role = "primary";
          waylandDescription = "Samsung Electric Company Odyssey G61SD";
          xrandrOutput = "DP-1";
          mode = {
            width = 2560;
            height = 1440;
            refresh = 239.76;
          };
          position = {
            x = 0;
            y = 0;
          };
          workspaces = [
            "1"
            "2"
            "3"
            "4"
            "5"
          ];
        };
        secondary = {
          role = "secondary";
          waylandDescription = "Samsung Electric Company LS27A600U";
          xrandrOutput = "HDMI-A-1";
          mode = {
            width = 2560;
            height = 1440;
            refresh = 74.97;
          };
          position = {
            x = 2560;
            y = 0;
          };
          rotation = 90;
          workspaces = [
            "6"
            "7"
            "8"
            "9"
          ];
        };
      };
    };
}
