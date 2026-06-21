{
  flake.nixosModules.rgb =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.rgb;
      openrgb = lib.getExe config.services.hardware.openrgb.package;
      color = lib.removePrefix "#" cfg.color;
      server = "127.0.0.1:${toString config.services.hardware.openrgb.server.port}";
      args = [
        "--client"
        server
        "--color"
        color
      ]
      ++ lib.optionals (cfg.mode != null) [
        "--mode"
        cfg.mode
      ]
      ++ lib.optionals (cfg.brightness != null) [
        "--brightness"
        (toString cfg.brightness)
      ]
      ++ lib.optionals (cfg.speed != null) [
        "--speed"
        (toString cfg.speed)
      ];

      hexColor = lib.types.strMatching "#?[0-9a-fA-F]{6}";
      percent = lib.types.ints.between 0 100;
    in
    {
      options.my.rgb = {
        enable = lib.mkEnableOption "declarative OpenRGB lighting";

        color = lib.mkOption {
          type = hexColor;
          default = config.my.colors.primary;
          defaultText = "config.my.colors.primary";
          description = "RGB color to apply, usually sourced from the main theme color.";
          example = "#89b4fa";
        };

        mode = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = "Static";
          description = "OpenRGB mode to use when applying the color.";
          example = "Static";
        };

        brightness = lib.mkOption {
          type = lib.types.nullOr percent;
          default = null;
          description = "Optional OpenRGB brightness percentage for modes that support it.";
          example = 80;
        };

        speed = lib.mkOption {
          type = lib.types.nullOr percent;
          default = null;
          description = "Optional OpenRGB effect speed percentage for modes that support it.";
          example = 50;
        };
      };

      config = lib.mkIf cfg.enable {
        services.hardware.openrgb.enable = true;

        systemd.services.openrgb-apply = {
          description = "Apply declarative OpenRGB lighting";
          requires = [ "openrgb.service" ];
          after = [ "openrgb.service" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };

          script = ''
            ${lib.escapeShellArgs ([ openrgb ] ++ args)}
          '';
        };

        systemd.timers.openrgb-apply = {
          description = "Apply declarative OpenRGB lighting after boot";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "1s";
            Unit = "openrgb-apply.service";
          };
        };
      };
    };
}
