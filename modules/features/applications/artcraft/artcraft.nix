{ self, ... }:
{
  flake.modules.nixos.artcraft =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      packages = import ./config/packages.nix { inherit lib pkgs; };
      cfg = config.my.artcraft;
    in
    {
      options.my.artcraft = lib.mapAttrs (
        name: package:
        {
          enable = lib.mkEnableOption "the ${name} desktop app, CLI and MCP launcher";
          package = lib.mkOption {
            type = lib.types.package;
            default = package;
            description = "Package to install when ${name} is selected.";
          };
        }
        // lib.optionalAttrs (name == "filmcraft") {
          mcp.mode = lib.mkOption {
            type = lib.types.enum [
              "headless"
              "bridge"
            ];
            default = "headless";
            description = ''
              OpenCode MCP mode: headless edits a separate engine session; bridge
              edits the live FilmCraft window started with filmcraft-agent.
              The bridge connects only to 127.0.0.1:9876 and does not launch the GUI.
            '';
          };
        }
      ) packages;
      config.environment.systemPackages = lib.mapAttrsToList (_: app: app.package) (
        lib.filterAttrs (_: app: app.enable) cfg
      );
    };
  perSystem =
    { lib, pkgs, ... }:
    let
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (
        import ./config/packages.nix { inherit lib pkgs; }
      );
    in
    {
      packages = packages // {
        artcraft-update = pkgs.writeShellApplication {
          name = "artcraft-update";
          runtimeInputs = [ pkgs.python3 ];
          text = ''
            exec python3 ${./config/update-releases.py} "$@"
          '';
        };
      };
      checks = {
        artcraft-updater = pkgs.runCommand "artcraft-updater" { nativeBuildInputs = [ pkgs.python3 ]; } ''
          python3 -B ${./config}/test-update.py
          touch $out
        '';
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        artcraft-cli = pkgs.runCommand "artcraft-cli" { nativeBuildInputs = [ pkgs.python3 ]; } ''
          python3 ${./config/test-cli.py} ${lib.escapeShellArgs (map toString (lib.attrValues packages))}
          touch $out
        '';
        artcraft-bridge = pkgs.runCommand "artcraft-bridge" { nativeBuildInputs = [ pkgs.python3 ]; } ''
          python3 ${./config/test-bridge.py} ${lib.getExe' packages.filmcraft "filmcraft-cli"}
          touch $out
        '';
        artcraft-selection = import ./config/test-selection.nix {
          inherit lib pkgs;
          module = self.modules.nixos.artcraft;
        };
      };
    };
}
