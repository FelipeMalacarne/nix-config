{ inputs, ... }:
{
  flake.modules.nixos.noctalia-greeter =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.displayManager.noctalia-greeter;
      i3Selected = builtins.elem "i3" config.my.desktop.sessions;
      allMonitors = lib.attrValues config.my.desktop.monitors;
      # X11-only hosts need not declare Wayland identities. Let the greeter use
      # its native output defaults for monitors that cannot be matched here.
      monitors = lib.filter (output: output.match.waylandDescription != null) allMonitors;
      modeSizes = lib.unique (map (output: { inherit (output.mode) width height; }) allMonitors);
      sessionData = config.services.displayManager.sessionData;
      xsession = pkgs.writeShellScriptBin "noctalia-greeter-xsession" ''
        set -eu
        if [ "$#" -lt 1 ]; then
          exit 1
        fi
        client="$1"
        shift
        resolved_client="$(command -v -- "$client" 2>/dev/null || true)"
        if [ -n "$resolved_client" ]; then
          client="$resolved_client"
        fi
        server_args=(-seat "''${XDG_SEAT:-seat0}" -keeptty)
        vt="''${XDG_VTNR:-}"
        if [ -z "$vt" ]; then
          current_tty="$(tty 2>/dev/null || true)"
          if [[ "$current_tty" =~ ^/dev/tty([0-9]+)$ ]]; then
            vt="''${BASH_REMATCH[1]}"
          fi
        fi
        if [ -n "$vt" ]; then
          server_args+=("vt$vt")
        fi
        # startx ignores automatic xserverrc selection when server arguments are present.
        exec ${pkgs.xinit}/bin/startx "$client" "$@" -- \
          ${config.environment.etc."X11/xinit/xserverrc".source} "''${server_args[@]}"
      '';
      # Greeter's explicit startx client bypasses NixOS's normal display-manager wrapper.
      sessions =
        pkgs.runCommand "noctalia-greeter-sessions"
          {
            nativeBuildInputs = [ pkgs.makeWrapper ];
          }
          ''
            mkdir -p "$out/share"
            cp -rs --no-preserve=mode ${sessionData.desktops}/share/. "$out/share/"
            ${lib.optionalString i3Selected ''
              source=${sessionData.desktops}/share/xsessions/none+i3.desktop
              client=$(sed -n 's/^Exec=//p' "$source")
              test -n "$client"
              mkdir -p "$out/bin"
              makeWrapper ${sessionData.wrapper} "$out/bin/noctalia-greeter-i3-session" \
                --set DESKTOP_SESSION none+i3 --add-flags "$client"
              rm "$out/share/xsessions/none+i3.desktop"
              substitute "$source" "$out/share/xsessions/none+i3.desktop" \
                --replace-fail "TryExec=$client" "TryExec=$out/bin/noctalia-greeter-i3-session" \
                --replace-fail "Exec=$client" "Exec=$out/bin/noctalia-greeter-i3-session"
            ''}
          '';
    in
    {
      imports = [ inputs.noctalia-greeter.nixosModules.default ];

      services.displayManager = {
        autoLogin.enable = false;
        noctalia-greeter = {
          enable = true;
          package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
          passwordless-sync-users = [ ];
          settings = {
            session.default = lib.mkIf (config.services.displayManager.defaultSession != null) (
              lib.mkDefault config.services.displayManager.defaultSession
            );
            cursor = {
              path = "${pkgs.bibata-cursors}";
              theme = "Bibata-Modern-Classic";
              size = 22;
            };
            keyboard = {
              inherit (config.services.xserver.xkb) layout variant options;
            };
            # Upstream never blanks by default; match the sessions' 240-second DPMS timeout.
            idle.timeout = lib.mkDefault 240;
            output =
              lib.optionalAttrs (monitors != [ ]) {
                layout = lib.concatMapStringsSep "; " (
                  output:
                  "${output.match.waylandDescription}:${toString output.position.x},${toString output.position.y}"
                ) monitors;
                refresh_rate = lib.concatMapStringsSep "; " (
                  output: "${output.match.waylandDescription}:${toString output.mode.refresh}"
                ) monitors;
                transforms = lib.concatMapStringsSep "; " (
                  output: "${output.match.waylandDescription}:${toString output.rotation}"
                ) monitors;
                scales = lib.concatMapStringsSep "; " (
                  output: "${output.match.waylandDescription}:${toString output.scale}"
                ) monitors;
              }
              # Upstream only supports a global size; never apply one monitor's size to others.
              // lib.optionalAttrs (monitors != [ ] && lib.length modeSizes == 1) (lib.head modeSizes);
          };
        };
      };

      services.xserver.displayManager.startx.enable = lib.mkIf i3Selected true;
      # Greeter launches this helper by name; do not replace its package or sync helper.
      environment.systemPackages = lib.mkIf i3Selected [ (lib.hiPrio xsession) ];
      services.greetd.settings.default_session.command =
        "${lib.getExe' pkgs.coreutils "env"} "
        + "XDG_DATA_DIRS=${sessions}/share "
        + "${cfg.package}/bin/noctalia-greeter-session -- ${cfg.greeter-args}";

      assertions = [
        {
          assertion = !(config.services.greetd.settings ? initial_session);
          message = "Noctalia Greeter must require login authentication; greetd initial_session is not allowed.";
        }
        {
          assertion = cfg.passwordless-sync-users == [ ];
          message = "Noctalia Greeter appearance sync must require administrator authentication.";
        }
      ];
    };
}
