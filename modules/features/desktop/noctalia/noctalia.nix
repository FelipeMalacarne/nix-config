{ inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        noctalia-export = pkgs.writeShellApplication {
          name = "noctalia-export";
          runtimeInputs = [
            inputs.noctalia.packages.${system}.default
            (pkgs.python3.withPackages (ps: [ ps.tomli-w ]))
          ];
          text = ''
            exec python3 ${./config/export.py} "$@"
          '';
        };
      };
    };

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
      noctalia = lib.getExe config.programs.noctalia.package;
    in
    {
      imports = [
        inputs.noctalia.homeModules.default
        ./config/settings.nix
      ];

      config = lib.mkMerge [
        {
          my.desktop.shellProviders.noctalia.commands = {
            launcher = "${noctalia} msg panel-toggle launcher";
            dashboard = "${noctalia} msg panel-toggle control-center";
            settings = "${noctalia} msg settings-toggle";
            session = "${noctalia} msg panel-toggle session";
            lock = "${noctalia} msg session lock";
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

            home.file."Pictures/nixos.svg".source = ../../../../assets/nixos.svg;

            stylix.targets.hyprpaper.enable = lib.mkForce false;
            services.hyprpaper.enable = lib.mkForce false;

            programs.noctalia = {
              enable = true;
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
