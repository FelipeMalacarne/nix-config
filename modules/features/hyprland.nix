{
  flake.nixosModules.hyprland = { config, pkgs, ... }:
    let
      user = config.my.user.name;
      wallpaperDir = ../../assets/wallpapers;
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

      services.displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
        };
        autoLogin = {
          enable = true;
          user = user;
        };
      };

      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-hyprland
          pkgs.xdg-desktop-portal-gtk
        ];
        config.common.default = "*";
      };

      environment.systemPackages = with pkgs; [
        kdePackages.qtsvg
      ];

      home-manager.users.${user} = {
          stylix.targets.hyprland.hyprpaper.enable = false;

          home.file = builtins.listToAttrs (
            map (f: {
              name = "Pictures/wallpapers/${f}";
              value.source = wallpaperDir + "/${f}";
            }) (builtins.attrNames (builtins.readDir wallpaperDir))
          ) // {
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
                lock_cmd = "noctalia-shell ipc call lockScreen lock";
                before_sleep_cmd = "noctalia-shell ipc call lockScreen lock";
                after_sleep_cmd = "/run/current-system/sw/bin/hyprctl dispatch dpms on";
              };

              listener = [
                {
                  timeout = 180;
                  on-timeout = "noctalia-shell ipc call lockScreen lock";
                }
                {
                  timeout = 240;
                  on-timeout = "/run/current-system/sw/bin/hyprctl dispatch dpms off";
                  on-resume = "/run/current-system/sw/bin/hyprctl dispatch dpms on";
                }
              ];
            };
          };

          wayland.windowManager.hyprland = {
            enable = true;
            settings = {
              "$mod" = "SUPER";
              "$ipc" = "noctalia-shell ipc call";

              exec-once = [
                "uwsm app -- noctalia-shell"
                "uwsm app -- bitwarden"
              ];

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
                "desc:Samsung Electric Company Odyssey G61SD HNBYB00003, 2560x1440@240, auto, 1"
                "desc:Samsung Electric Company LS27A600U HNMW900149, 2560x1440@75, auto-left, 1, transform, 1"
              ];

              workspace = [
                "1, monitor:desc:Samsung Electric Company Odyssey G61SD HNBYB00003"
                "2, monitor:desc:Samsung Electric Company Odyssey G61SD HNBYB00003"
                "3, monitor:desc:Samsung Electric Company Odyssey G61SD HNBYB00003"
                "4, monitor:desc:Samsung Electric Company Odyssey G61SD HNBYB00003"
                "5, monitor:desc:Samsung Electric Company Odyssey G61SD HNBYB00003"
                "6, monitor:desc:Samsung Electric Company LS27A600U HNMW900149"
                "7, monitor:desc:Samsung Electric Company LS27A600U HNMW900149"
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
                "$mod, Space, exec, $ipc launcher toggle"
                "$mod, C, exec, $ipc controlCenter toggle"
                "$mod, comma, exec, $ipc settings toggle"
                "$mod SHIFT, Escape, exec, $ipc sessionMenu toggle"
                "$mod Control, L, exec, $ipc lockScreen lock"
                "$mod, H, movefocus, l"
                "$mod, L, movefocus, r"
                "$mod, K, movefocus, u"
                "$mod, J, movefocus, d"
                "$mod SHIFT, H, movewindow, l"
                "$mod SHIFT, L, movewindow, r"
                "$mod SHIFT, K, movewindow, u"
                "$mod SHIFT, J, movewindow, d"
                "$mod, 1, workspace, 1"
                "$mod, 2, workspace, 2"
                "$mod, 3, workspace, 3"
                "$mod, 4, workspace, 4"
                "$mod, 5, workspace, 5"
                "$mod, 6, workspace, 6"
                "$mod, 7, workspace, 7"
                "$mod SHIFT, 1, movetoworkspace, 1"
                "$mod SHIFT, 2, movetoworkspace, 2"
                "$mod SHIFT, 3, movetoworkspace, 3"
                "$mod SHIFT, 4, movetoworkspace, 4"
                "$mod SHIFT, 5, movetoworkspace, 5"
                "$mod SHIFT, 6, movetoworkspace, 6"
                "$mod SHIFT, 7, movetoworkspace, 7"
                "$mod SHIFT, F, exec, uwsm app -- $TERMINAL -e yazi"
                "$mod SHIFT, T, exec, uwsm app -- $TERMINAL -e btop"
                "$mod SHIFT, I, exec, uwsm app -- $TERMINAL -e bash -c 'fastfetch; read -rp \"Press enter to close...\"'"
                "$mod SHIFT, B, exec, uwsm app -- firefox"
              ];

              bindm = [
                "$mod, mouse:272, movewindow"
                "$mod, mouse:273, resizewindow"
              ];

              bindel = [
                ", XF86AudioRaiseVolume, exec, $ipc volume increase"
                ", XF86AudioLowerVolume, exec, $ipc volume decrease"
              ];

              bindl = [
                ", XF86AudioMute, exec, $ipc volume muteOutput"
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
