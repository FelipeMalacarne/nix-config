{ ... }:
{
  flake.nixosModules.hyprland =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      user = config.my.user.name;
      noctalia = lib.getExe pkgs.noctalia-shell;
      brightnessctl = lib.getExe pkgs.brightnessctl;
      grimblast = lib.getExe pkgs.grimblast;
      hyprctl = "${pkgs.hyprland}/bin/hyprctl";
      playerctl = lib.getExe pkgs.playerctl;
      wallpaperDir = ../../assets/wallpapers;
      wpctl = "${pkgs.wireplumber}/bin/wpctl";

      monitorMain = "DP-1";
      monitorSide = "HDMI-A-1";

      refreshLayerClients = pkgs.writeShellScript "refresh-hyprland-layer-clients" ''
        sleep 0.5
        ${pkgs.systemd}/bin/systemctl --user stop hyprpaper.service 2>/dev/null || true
        ${pkgs.procps}/bin/pkill -u "$USER" -f 'quickshell.*noctalia-shell' 2>/dev/null || true
        sleep 0.2
        exec uwsm app -- ${noctalia}
      '';

      startLockedNoctalia = pkgs.writeShellScript "start-locked-noctalia" ''
        uwsm app -- ${noctalia} &

        for _ in $(${pkgs.coreutils}/bin/seq 1 100); do
          if ${noctalia} ipc call lockScreen lock 2>/dev/null; then
            exit 0
          fi
          ${pkgs.coreutils}/bin/sleep 0.1
        done

        ${noctalia} ipc call lockScreen lock 2>/dev/null || true
      '';

      termHere = pkgs.writeShellScript "term-here" ''
        pid=$(hyprctl activewindow -j 2>/dev/null | ${pkgs.jq}/bin/jq -r '.pid // empty')
        cwd=""
        if [ -n "$pid" ]; then
          while child=$(pgrep -P "$pid" 2>/dev/null | head -1) && [ -n "$child" ]; do
            pid=$child
          done
          cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null)
        fi
        if [ -n "$cwd" ] && [ -d "$cwd" ]; then
          exec uwsm app -- $TERMINAL --working-directory="$cwd"
        else
          exec uwsm app -- $TERMINAL
        fi
      '';

    in
    {
      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };

      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-hyprland
          pkgs.xdg-desktop-portal-gtk
        ];
        config.common.default = "*";
      };

      home-manager.users.${user} = {
        home.file =
          builtins.listToAttrs (
            map (f: {
              name = "Pictures/wallpapers/${f}";
              value.source = wallpaperDir + "/${f}";
            }) (builtins.attrNames (builtins.readDir wallpaperDir))
          )
          // {
            ".XCompose".text = ''
              include "%L"
              <dead_acute> <c> : "ç" ccedilla
              <dead_acute> <C> : "Ç" Ccedilla
            '';
          };

        gtk = {
          enable = true;
          gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
          gtk4 = {
            extraConfig.gtk-application-prefer-dark-theme = true;
            theme = null;
          };
        };

        dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

        home.pointerCursor = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Modern-Classic";
          size = 16;
          gtk.enable = true;
          x11.enable = true;
        };

        systemd.user.sessionVariables = {
          XCURSOR_THEME = "Bibata-Modern-Classic";
          XCURSOR_SIZE = "22";
          XCOMPOSEFILE = "$HOME/.XCompose";
        };

        services.hypridle = {
          enable = true;
          settings = {
            general = {
              lock_cmd = "${noctalia} ipc call lockScreen lock";
              before_sleep_cmd = "${noctalia} ipc call lockScreen lock";
              after_sleep_cmd = "${hyprctl} dispatch dpms on";
            };
            listener = [
              {
                timeout = 180;
                on-timeout = "${noctalia} ipc call lockScreen lock";
              }
              {
                timeout = 240;
                on-timeout = "${hyprctl} dispatch dpms off";
                on-resume = "${hyprctl} dispatch dpms on";
              }
            ];
          };
        };

        wayland.windowManager.hyprland = {
          enable = true;
          settings = {
            "$mod" = "SUPER";
            "$ipc" = "${noctalia} ipc call";

            exec-once = [
              "uwsm app -- ${noctalia}"
              # "${startLockedNoctalia}"
              # "uwsm app -- ${lib.getExe pkgs.bitwarden-desktop}"
            ];

            # exec = [
            #   "${refreshLayerClients}"
            # ];

            env = [
              "NVD_BACKEND,direct"
              "LIBVA_DRIVER_NAME,nvidia"
              "__GLX_VENDOR_LIBRARY_NAME,nvidia"
              "GDK_SCALE,1"
              "LC_CTYPE,pt_BR.UTF-8"
              "XCOMPOSEFILE,$HOME/.XCompose"
              "XCURSOR_THEME,Bibata-Modern-Classic"
              "XCURSOR_SIZE,22"
              "QT_QPA_PLATFORMTHEME,kde"
            ];

            monitor = [
              "${monitorMain}, 2560x1440@240, 0x0, 1"
              "${monitorSide}, 2560x1440@75, 2560x0, 1"
            ];

            workspace = [
              "1, monitor:${monitorMain}"
              "2, monitor:${monitorMain}"
              "3, monitor:${monitorMain}"
              "4, monitor:${monitorMain}"
              "5, monitor:${monitorMain}"
              "6, monitor:${monitorSide}"
              "7, monitor:${monitorSide}"
              "8, monitor:${monitorSide}"
              "9, monitor:${monitorSide}"
            ];

            input = {
              kb_layout = "us";
              kb_variant = "intl";
              follow_mouse = 1;
              touchpad.natural_scroll = false;
              kb_options = "caps:shiftlock";
              repeat_rate = 40;
              repeat_delay = 600;
            };

            bind = [
              "$mod, Return, exec, ${termHere}"

              "$mod, W, killactive"
              "$mod, F, fullscreen"
              "$mod, T, togglefloating"
              "$mod, E, layoutmsg, togglesplit"
              "$mod, P, pseudo"
              "$mod SHIFT, P, pin"
              "$mod SHIFT, R, exec, ${hyprctl} reload"
              "$mod SHIFT, Q, exit"

              # noctalia
              "$mod, Space, exec, $ipc launcher toggle"
              "$mod, period, exec, $ipc controlCenter toggle"
              "$mod, comma, exec, $ipc settings toggle"
              "$mod, Delete, exec, $ipc sessionMenu toggle"
              "$mod Control, L, exec, $ipc lockScreen lock"

              "$mod, S, togglespecialworkspace, scratch"
              "$mod SHIFT, S, movetoworkspacesilent, special:scratch"
              ", Print, exec, ${grimblast} copy output"
              "SHIFT, Print, exec, ${grimblast} copy area"
              "$mod, Print, exec, ${grimblast} save area"
              "$mod, H, movefocus, l"
              "$mod, L, movefocus, r"
              "$mod, K, movefocus, u"
              "$mod, J, movefocus, d"
              "$mod SHIFT, H, movewindow, l"
              "$mod SHIFT, L, movewindow, r"
              "$mod SHIFT, K, movewindow, u"
              "$mod SHIFT, J, movewindow, d"
              "$mod, Tab, workspace, previous"
              "$mod, bracketright, workspace, e+1"
              "$mod, bracketleft, workspace, e-1"
              "$mod, period, focusmonitor, +1"
              "$mod SHIFT, period, movewindow, mon:+1"

              "$mod SHIFT, F, exec, uwsm app -- $TERMINAL -e ${lib.getExe pkgs.yazi}"
              "$mod SHIFT, T, exec, uwsm app -- $TERMINAL -e ${lib.getExe pkgs.btop}"
              "$mod SHIFT, I, exec, uwsm app -- $TERMINAL -e ${lib.getExe pkgs.bash} -c '${lib.getExe pkgs.fastfetch}; read -rp \"Press enter to close...\"'"
              "$mod SHIFT, B, exec, uwsm app -- ${lib.getExe pkgs.firefox}"

              "$mod, 1, workspace, 1"
              "$mod, 2, workspace, 2"
              "$mod, 3, workspace, 3"
              "$mod, 4, workspace, 4"
              "$mod, 5, workspace, 5"
              "$mod, 6, workspace, 6"
              "$mod, 7, workspace, 7"
              "$mod, 8, workspace, 8"
              "$mod, 9, workspace, 9"
              "$mod SHIFT, 1, movetoworkspace, 1"
              "$mod SHIFT, 2, movetoworkspace, 2"
              "$mod SHIFT, 3, movetoworkspace, 3"
              "$mod SHIFT, 4, movetoworkspace, 4"
              "$mod SHIFT, 5, movetoworkspace, 5"
              "$mod SHIFT, 6, movetoworkspace, 6"
              "$mod SHIFT, 7, movetoworkspace, 7"
              "$mod SHIFT, 8, movetoworkspace, 8"
              "$mod SHIFT, 9, movetoworkspace, 9"
            ];

            binde = [
              "$mod ALT, H, resizeactive, -80 0"
              "$mod ALT, L, resizeactive, 80 0"
              "$mod ALT, K, resizeactive, 0 -80"
              "$mod ALT, J, resizeactive, 0 80"
            ];

            bindm = [
              "$mod, mouse:272, movewindow"
              "$mod, mouse:273, resizewindow"
            ];

            bindel = [
              ", XF86AudioRaiseVolume, exec, $ipc volume increase"
              ", XF86AudioLowerVolume, exec, $ipc volume decrease"
              ", XF86MonBrightnessUp, exec, ${brightnessctl} set +5%"
              ", XF86MonBrightnessDown, exec, ${brightnessctl} set 5%-"
            ];

            bindl = [
              ", XF86AudioMute, exec, $ipc volume muteOutput"
              ", XF86AudioMicMute, exec, ${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
              ", XF86AudioPlay, exec, ${playerctl} play-pause"
              ", XF86AudioNext, exec, ${playerctl} next"
              ", XF86AudioPrev, exec, ${playerctl} previous"
            ];

            animations = {
              enabled = true;
              bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
              animation = [
                "windows, 1, 7, myBezier"
                "windowsOut, 1, 7, default, popin 80%"
                "border, 1, 10, default"
                "fade, 1, 7, default"
                "workspaces, 1, 6, default"
              ];
            };

            windowrule = [
              {
                name = "bitwarden-workspace";
                workspace = "5 silent";
                "match:class" = "^(Bitwarden)$";
              }
            ];

            general = {
              gaps_in = 5;
              gaps_out = 10;
              border_size = 2;
              layout = "dwindle";
            };

            decoration = {
              rounding = 20;
              rounding_power = 2;
              shadow = {
                enabled = true;
                range = 4;
                render_power = 3;
              };
              blur = {
                enabled = true;
                size = 3;
                passes = 2;
                vibrancy = 0.1696;
              };
            };

            layerrule = [
              {
                name = "noctalia";
                "match:namespace" = "noctalia-background-.*";
                blur = true;
                ignore_alpha = 0.5;
              }
              {
                name = "noctalia-shell-region";
                "match:namespace" = "noctalia-shell:regionSelector";
                no_anim = true;
              }
            ];

            misc = {
              force_default_wallpaper = 0;
              disable_hyprland_logo = true;
            };

            dwindle.preserve_split = true;
          };
        };
      };
    };
}
