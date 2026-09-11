{ ... }:
{
  flake.nixosModules.i3 =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkIf (builtins.elem "i3" config.my.desktop.sessions) {
      services.xserver.windowManager.i3 = {
        enable = true;
        package = pkgs.i3;
        extraPackages = [ pkgs.i3status ];
      };
      environment.systemPackages = with pkgs; [
        rofi
        feh
        flameshot
        picom
        polkit_gnome
      ];
    };

  flake.homeModules.i3 =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      colors = {
        success = "#${config.lib.stylix.colors.base0B}";
        warning = "#${config.lib.stylix.colors.base0A}";
        error = "#${config.lib.stylix.colors.base08}";
      };
      wallpaper = ../../assets/wallpapers/catppuccin-mocha.png;
      menu = "${lib.getExe pkgs.rofi} -show drun";
      feh = lib.getExe pkgs.feh;
      picom = lib.getExe pkgs.picom;
      flameshot = lib.getExe pkgs.flameshot;
      flameshotFull = "${flameshot} full -c";
      flameshotArea = "${flameshot} gui";
      flameshotSave = "${flameshot} gui -s";
      polkitAgent = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";

      wpctl = "${pkgs.wireplumber}/bin/wpctl";
      playerctl = lib.getExe pkgs.playerctl;
      brightnessctl = lib.getExe pkgs.brightnessctl;
      topologyI3 = lib.concatMapStrings (
        output:
        lib.concatMapStrings (
          workspace: "workspace ${workspace} output ${output.match.xrandrOutput}\n"
        ) output.workspaces
      ) (lib.attrValues config.my.desktop.monitors);
    in
    {
      config = lib.mkIf (builtins.elem "i3" config.my.desktop.sessions) {
        xsession.windowManager.i3 =
          let
            mod = "Mod4";
            stylixBar = config.stylix.targets.i3.exportedBarConfig;
          in
          {
            enable = true;
            package = pkgs.i3;

            config = {
              modifier = mod;
              menu = menu;

              gaps = {
                inner = 5;
                outer = 10;
                smartGaps = false;
                smartBorders = "off";
              };

              window.border = 2;
              floating.modifier = mod;

              keybindings = {
                # Terminal is compositor-specific (Hyprland uses termHere).
                "${mod}+Return" = "exec ${config.my.desktop.terminalCommand}";

                # Window ops (mirrors Hyprland: W=kill, F=fullscreen, T=float, E=split, P=layout)
                "${mod}+w" = "kill";
                "${mod}+f" = "fullscreen toggle";
                "${mod}+t" = "floating toggle";
                "${mod}+e" = "layout toggle split";
                "${mod}+p" = "layout toggle all";
                "${mod}+Shift+r" = "restart";
                "${mod}+Shift+q" = "exit";

                # Launcher (mirrors $mod+Space in Hyprland)
                "${mod}+space" = "exec ${menu}";

                # Focus (HJKL mirrors Hyprland movefocus)
                "${mod}+h" = "focus left";
                "${mod}+l" = "focus right";
                "${mod}+k" = "focus up";
                "${mod}+j" = "focus down";

                # Move window (mirrors Hyprland movewindow)
                "${mod}+Shift+h" = "move left";
                "${mod}+Shift+l" = "move right";
                "${mod}+Shift+k" = "move up";
                "${mod}+Shift+j" = "move down";

                # Workspace navigation (mirrors Hyprland)
                "${mod}+Tab" = "workspace back_and_forth";
                "${mod}+bracketright" = "workspace next";
                "${mod}+bracketleft" = "workspace prev";
                "${mod}+period" = "focus output right";
                "${mod}+Shift+period" = "move container to output right";

                # Scratchpad (mirrors Hyprland special:scratch)
                "${mod}+s" = "scratchpad show";
                "${mod}+Shift+s" = "move scratchpad";

                # Workspace switching
                "${mod}+1" = "workspace number 1";
                "${mod}+2" = "workspace number 2";
                "${mod}+3" = "workspace number 3";
                "${mod}+4" = "workspace number 4";
                "${mod}+5" = "workspace number 5";
                "${mod}+6" = "workspace number 6";
                "${mod}+7" = "workspace number 7";
                "${mod}+8" = "workspace number 8";
                "${mod}+9" = "workspace number 9";

                # Move container to workspace
                "${mod}+Shift+1" = "move container to workspace number 1";
                "${mod}+Shift+2" = "move container to workspace number 2";
                "${mod}+Shift+3" = "move container to workspace number 3";
                "${mod}+Shift+4" = "move container to workspace number 4";
                "${mod}+Shift+5" = "move container to workspace number 5";
                "${mod}+Shift+6" = "move container to workspace number 6";
                "${mod}+Shift+7" = "move container to workspace number 7";
                "${mod}+Shift+8" = "move container to workspace number 8";
                "${mod}+Shift+9" = "move container to workspace number 9";

                # Screenshots (X11: flameshot replaces Wayland grimblast)
                "Print" = "exec ${flameshotFull}";
                "Shift+Print" = "exec ${flameshotArea}";
                "${mod}+Print" = "exec ${flameshotSave}";

                # Resize (mirrors Hyprland binde $mod+Alt+HJKL)
                "${mod}+Mod1+h" = "resize shrink width 80 px or 80 ppt";
                "${mod}+Mod1+l" = "resize grow width 80 px or 80 ppt";
                "${mod}+Mod1+k" = "resize shrink height 80 px or 80 ppt";
                "${mod}+Mod1+j" = "resize grow height 80 px or 80 ppt";

                # Audio (mirrors Hyprland bindel/bindl)
                "XF86AudioRaiseVolume" = "exec --no-startup-id ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%+";
                "XF86AudioLowerVolume" = "exec --no-startup-id ${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
                "XF86AudioMute" = "exec --no-startup-id ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
                "XF86AudioMicMute" = "exec --no-startup-id ${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
                "XF86AudioPlay" = "exec --no-startup-id ${playerctl} play-pause";
                "XF86AudioNext" = "exec --no-startup-id ${playerctl} next";
                "XF86AudioPrev" = "exec --no-startup-id ${playerctl} previous";

                # Brightness (mirrors Hyprland bindel)
                "XF86MonBrightnessUp" = "exec --no-startup-id ${brightnessctl} set +5%";
                "XF86MonBrightnessDown" = "exec --no-startup-id ${brightnessctl} set 5%-";
              };

              startup = [
                {
                  command = "${feh} --bg-fill ${wallpaper}";
                  always = true;
                  notification = false;
                }
                {
                  command = "${picom} -b";
                  always = true;
                  notification = false;
                }
                {
                  command = "${polkitAgent}";
                  always = false;
                  notification = false;
                }
              ];

              bars = [
                (
                  stylixBar
                  // {
                    statusCommand = "i3status";
                    position = "top";
                    trayOutput = "none";
                  }
                )
              ];
            };

            extraConfig = ''
              default_border pixel 2
              default_floating_border pixel 2
              ${topologyI3}
            '';
          };

        programs.i3status = {
          enable = true;
          general = {
            colors = true;
            color_good = colors.success;
            color_degraded = colors.warning;
            color_bad = colors.error;
            interval = 5;
          };
        };
      };
    };
}
