{ inputs, config, ... }:
let
  registry = config.flake.modules;
in
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

  flake.modules.nixos.noctalia = {
    my.desktop.shell = "noctalia";
    home-manager.sharedModules = [ registry.homeManager.noctalia ];
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
      options,
      ...
    }:
    let
      noctalia = lib.getExe config.programs.noctalia.package;
      supportedSessions = [
        "hyprland"
        "umbriel"
      ];
    in
    {
      imports = [
        inputs.noctalia.homeModules.default
        ./config/settings.nix
      ];

      config = lib.mkMerge [
        {
          my.desktop.shellProviders.noctalia = {
            inherit supportedSessions;
            startupCommand = noctalia;
            commands = {
              launcher = "${noctalia} msg panel-toggle launcher";
              dashboard = "${noctalia} msg panel-toggle control-center";
              settings = "${noctalia} msg settings-toggle";
              session = "${noctalia} msg panel-toggle session";
              lock = "${noctalia} msg session lock";
            };
          };

          home.packages = with pkgs; [
            grim
            imagemagick
            swappy
            tesseract
            xdg-utils
            jq
            wf-recorder
          ];

          home.file."Pictures/nixos.svg".source = ./config/nixos.svg;

          programs.noctalia = {
            enable = true;
          };
        }
        # A definition under mkIf false still needs its option, so key the rules on
        # Umbriel's Home Manager module being imported.
        (lib.optionalAttrs (options.programs ? umbriel) {
          programs.umbriel.settings = {
            window_rule = [
              {
                match.app_id = "^dev.noctalia.Noctalia$";
                default_floating = true;
                default_floating_size_px = {
                  width = 1080;
                  height = 920;
                };
              }
            ];
            layer_rule = [
              {
                match.namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher|desktop-widget-.+)$";
                blur = true;
                blur_ignore_alpha = 0.5;
                blur_popups = true;
              }
            ];
          };
        })
        (lib.mkIf (builtins.elem "hyprland" config.my.desktop.sessions) {
          stylix.targets.hyprpaper.enable = lib.mkForce false;
          services.hyprpaper.enable = lib.mkForce false;

          wayland.windowManager.hyprland.extraLuaFiles.noctalia = {
            content = builtins.replaceStrings [ "@NOCTALIA@" ] [ (builtins.toJSON noctalia) ] (
              builtins.readFile ./config/startup.lua
            );
            autoLoad = true;
          };
        })
      ];
    };
}
