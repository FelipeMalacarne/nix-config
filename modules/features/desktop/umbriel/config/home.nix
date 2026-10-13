{
  config,
  lib,
  pkgs,
  ...
}:
let
  umbriel = lib.getExe config.programs.umbriel.package;
  shellCommands = config.my.desktop.shellCommands;
  shellCommand = name: if shellCommands.${name} == null then ":" else shellCommands.${name};
  once = action: {
    inherit action;
    repeat = false;
  };
  spawn = command: once "spawn:${command}";
  wpctl = "${pkgs.wireplumber}/bin/wpctl";
  playerctl = lib.getExe pkgs.playerctl;
  brightnessctl = lib.getExe pkgs.brightnessctl;
  workspaceNames = map toString (lib.range 1 9);
  workspaceBindings = builtins.listToAttrs (
    lib.concatMap (name: [
      # Quoting forces name lookup, not a per-output numeric position.
      (lib.nameValuePair "Mod+${name}" "workspace-switch:${builtins.toJSON name}")
      (lib.nameValuePair "Mod+Shift+${name}" "window-move-to-workspace:${builtins.toJSON name}")
    ]) workspaceNames
  );
  movementBindings = builtins.listToAttrs (
    lib.concatMap
      (direction: [
        (lib.nameValuePair "Mod+${lib.toUpper direction}" "window-focus-${direction}")
        (lib.nameValuePair "Mod+Shift+${lib.toUpper direction}" "window-swap-${direction}")
        (lib.nameValuePair "Mod+Ctrl+${lib.toUpper direction}" "window-move-${direction}")
      ])
      [
        "left"
        "down"
        "up"
        "right"
      ]
  );
  applicationBindings = builtins.listToAttrs (
    map (
      binding:
      lib.nameValuePair (lib.concatStringsSep "+" (
        [ "Mod" ] ++ map lib.toUpper binding.modifiers ++ [ (lib.toUpper binding.key) ]
      )) (spawn binding.command)
    ) (lib.attrValues config.my.desktop.applicationBindings)
  );
  monitors = lib.attrValues config.my.desktop.monitors;
  colors = config.lib.stylix.colors.withHashtag;
in
{
  config = lib.mkIf (builtins.elem "umbriel" config.my.desktop.sessions) {
    programs.umbriel = {
      enable = true;
      settings = {
        general = {
          mod_key = "Super";
          xwayland = true;
          autostart = lib.optional (
            config.my.desktop.shellStartupCommand != null
          ) config.my.desktop.shellStartupCommand;
        };
        layout = {
          mode = "scrolling";
          gap = 8;
          extent_presets = [
            0.333
            0.5
            0.667
          ];
          scrolling.default_extent_fraction = 0.5;
        };
        appearance = {
          border_width = 2;
          corner_radius = 10;
          tab_bar.font = "${config.stylix.fonts.sansSerif.name} ${toString config.stylix.fonts.sizes.desktop}";
        };
        colors = {
          background = colors.base00;
          text_primary = colors.base05;
          text_muted = colors.base04;
          accent_primary = colors.base0D;
          accent_secondary = colors.base0E;
          warning = colors.base0A;
          error = colors.base08;
          backdrop = colors.base00;
          border = {
            focused = colors.base0D;
            unfocused = colors.base03;
            outer = colors.base01;
          };
        };
        input = {
          keyboard = {
            layout = "us";
            variant = "intl";
            options = "caps:shiftlock";
            repeat_rate = 40;
            repeat_delay = 600;
          };
          cursor = {
            theme = config.home.pointerCursor.name;
            size = config.home.pointerCursor.size;
          };
        };
        output = builtins.listToAttrs (
          map (
            monitor:
            lib.nameValuePair monitor.match.waylandDescription (
              {
                mode = "${toString monitor.mode.width}x${toString monitor.mode.height}@${toString monitor.mode.refresh}";
                position = [
                  monitor.position.x
                  monitor.position.y
                ];
                inherit (monitor) scale;
                transform = if monitor.rotation == 0 then "normal" else toString monitor.rotation;
                focus_at_startup = monitor.role == "primary";
              }
              // lib.optionalAttrs (monitor.workspaces != [ ]) {
                inherit (monitor) workspaces;
              }
            )
          ) monitors
        );
        workspace = lib.optionals (monitors == [ ]) (map (name: { inherit name; }) workspaceNames);
        window_rule = lib.optionals (config.my.desktop.shell == "noctalia") [
          {
            match.app_id = "^dev.noctalia.Noctalia$";
            default_floating = true;
            default_floating_size_px = {
              width = 1080;
              height = 920;
            };
          }
        ];
        layer_rule = lib.optionals (config.my.desktop.shell == "noctalia") [
          {
            match.namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher|desktop-widget-.+)$";
            blur = true;
            blur_ignore_alpha = 0.5;
            blur_popups = true;
          }
        ];
        keybinds = {
          "Mod+Return" = spawn config.my.desktop.terminalCommand;
          "Mod+W" = once "window-close";
          "Mod+Q" = once "window-close";
          "Mod+F" = once "window-toggle-fullscreen";
          "Mod+T" = once "window-toggle-floating";
          "Mod+Shift+P" = once "window-toggle-pinned";
          "Mod+Shift+R" = once "config-reload";
          "Mod+Shift+Q" = once "session-quit";
          "Mod+Shift+Escape" = (once "shortcuts-inhibit-toggle") // {
            allow_when_inhibited = true;
          };
          "Mod+Space" = spawn (shellCommand "launcher");
          "Mod+Period" = spawn (shellCommand "dashboard");
          "Mod+Comma" = spawn (shellCommand "settings");
          "Mod+Delete" = spawn (shellCommand "session");
          "Mod+L" = spawn (shellCommand "lock");
          "Mod+S" = once "scratchpad-toggle";
          "Mod+Shift+S" = once "window-move-to-scratchpad";
          "Mod+Ctrl+S" = once "window-restore-from-scratchpad";
          "Mod+Tab" = "workspace-focus-last";
          "Mod+BracketRight" = "workspace-next";
          "Mod+BracketLeft" = "workspace-previous";
          "Mod+Shift+Period" = "window-move-to-output-next";
          "Mod+E" = once "column-toggle-tabbed";
          "Mod+Alt+Right" = "column-focus-tab-next";
          "Mod+Alt+Left" = "column-focus-tab-previous";
          "Mod+O" = once "overview-toggle";
          "Mod+R" = "window-cycle-primary-extent";
          "XF86AudioRaiseVolume" = "spawn:${wpctl} set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+";
          "XF86AudioLowerVolume" = "spawn:${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          "XF86MonBrightnessUp" = "spawn:${brightnessctl} set +5%";
          "XF86MonBrightnessDown" = "spawn:${brightnessctl} set 5%-";
          "XF86AudioMute" = (spawn "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle") // {
            allow_when_locked = true;
          };
          "XF86AudioMicMute" = (spawn "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle") // {
            allow_when_locked = true;
          };
          "XF86AudioPlay" = (spawn "${playerctl} play-pause") // {
            allow_when_locked = true;
          };
          "XF86AudioNext" = (spawn "${playerctl} next") // {
            allow_when_locked = true;
          };
          "XF86AudioPrev" = (spawn "${playerctl} previous") // {
            allow_when_locked = true;
          };
        }
        // workspaceBindings
        // movementBindings
        // applicationBindings;
      };
    };

    services.swayidle = {
      enable = true;
      systemdTargets = [ "umbriel-session.target" ];
      timeouts = [
        {
          timeout = 180;
          command = shellCommand "lock";
        }
        {
          timeout = 240;
          command = "${umbriel} msg dpms-off";
          resumeCommand = "${umbriel} msg dpms-on";
        }
      ];
      events = {
        lock = shellCommand "lock";
        before-sleep = shellCommand "lock";
        after-resume = "${umbriel} msg dpms-on";
      };
    };
  };
}
