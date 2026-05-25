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

      hexColor = lib.types.strMatching "#?[0-9a-fA-F]{6}";
      percent = lib.types.ints.between 0 100;
      optionalArg =
        option: value:
        lib.optionalString (value != null) ''
          common_args+=("${option}" "${toString value}")
        '';
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

        argbHeaderLedCount = lib.mkOption {
          type = lib.types.ints.between 1 2048;
          default = 30;
          description = "Default LED count for auto-detected motherboard ARGB headers.";
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
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };

          script = ''
            openrgb=${lib.escapeShellArg openrgb}
            server=${lib.escapeShellArg server}
            color=${lib.escapeShellArg color}
            argb_header_led_count=${toString cfg.argbHeaderLedCount}

            common_args=()
            ${optionalArg "--mode" cfg.mode}
            common_args+=("--color" "$color")
            ${optionalArg "--brightness" cfg.brightness}
            ${optionalArg "--speed" cfg.speed}

            run_openrgb() {
              "$openrgb" --client "$server" "$@"
            }

            configure_argb_headers() {
              local device=""
              local line zones zone zone_index

              while IFS= read -r line; do
                case "$line" in
                  [0-9]*:*)
                    device="''${line%%:*}"
                    ;;
                  "  Zones:"*)
                    zones="''${line#*Zones:}"
                    zone_index=0

                    for zone in $zones; do
                      zone="''${zone#\'}"
                      zone="''${zone%\'}"

                      case "$zone" in
                        JRAINBOW* | *ARGB* | D_LED* | ADD_HEADER*)
                          run_openrgb \
                            --device "$device" \
                            --zone "$zone_index" \
                            --size "$argb_header_led_count" \
                            "''${common_args[@]}"
                          ;;
                      esac

                      zone_index=$((zone_index + 1))
                    done
                    ;;
                esac
              done < <(run_openrgb --list-devices)
            }

            configure_devices() {
              local device line

              while IFS= read -r line; do
                case "$line" in
                  [0-9]*:*)
                    device="''${line%%:*}"
                    run_openrgb --device "$device" "''${common_args[@]}"
                    ;;
                esac
              done < <(run_openrgb --list-devices)
            }

            apply_rgb() {
              configure_argb_headers
              configure_devices
            }

            attempt=1
            while [ "$attempt" -le 20 ]; do
              if apply_rgb; then
                exit 0
              fi

              attempt=$((attempt + 1))
              ${pkgs.coreutils}/bin/sleep 1
            done

            apply_rgb
          '';
        };
      };
    };
}
