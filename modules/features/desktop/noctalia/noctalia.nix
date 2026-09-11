{ inputs, ... }:
{
  flake.modules.nixos.noctalia =
    { config, lib, ... }:
    lib.mkIf
      (config.my.desktop.shell == "noctalia" && builtins.elem "hyprland" config.my.desktop.sessions)
      {
        nix.settings = {
          extra-substituters = [ "https://noctalia.cachix.org" ];
          extra-trusted-public-keys = [
            "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
          ];
        };
      };

  flake.modules.homeManager.noctalia =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      noctalia = lib.getExe pkgs.noctalia-shell;
    in
    {
      imports = [
        inputs.noctalia.homeModules.default
        ./config/settings.nix
      ];

      config = lib.mkMerge [
        {
          my.desktop.shellProviders.noctalia.commands = {
            launcher = "${noctalia} ipc call launcher toggle";
            dashboard = "${noctalia} ipc call controlCenter toggle";
            settings = "${noctalia} ipc call settings toggle";
            session = "${noctalia} ipc call sessionMenu toggle";
            lock = "${noctalia} ipc call lockScreen lock";
          };
        }
        (lib.mkIf
          (config.my.desktop.shell == "noctalia" && builtins.elem "hyprland" config.my.desktop.sessions)
          {
            home.packages = with pkgs; [
              grim
              imagemagick
              swappy
              tesseract
              xdg-utils
              jq
              wf-recorder
            ];

            stylix.targets.hyprpaper.enable = lib.mkForce false;
            services.hyprpaper.enable = lib.mkForce false;

            programs.noctalia-shell = {
              enable = true;
              # Colors, fonts, and opacity are managed by noctalia's native stylix
              # integration (mkTarget in noctalia-qs hm.nix). No need to set them here.
            };
            wayland.windowManager.hyprland.extraLuaFiles.noctalia = {
              content = builtins.replaceStrings [ "@NOCTALIA@" ] [ (builtins.toJSON noctalia) ] (
                builtins.readFile ./config/startup.lua
              );
              autoLoad = true;
            };
          }
        )
      ];
    };
}
