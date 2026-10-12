{ config, lib, ... }:
let
  commandNames = [
    "launcher"
    "dashboard"
    "settings"
    "session"
    "lock"
  ];
  providers = config.my.desktop.shellProviders;
  shell = config.my.desktop.shell;
  selected = shell != "none" && lib.hasAttr shell providers;
  commands = if selected then providers.${shell}.commands else { };
  waylandSessions = lib.filter (session: session != "i3") config.my.desktop.sessions;
in
{
  options.my.desktop.shellProviders = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          supportedSessions = lib.mkOption {
            type = lib.types.listOf (
              lib.types.enum [
                "hyprland"
                "umbriel"
              ]
            );
            description = "Wayland sessions supported by this shell provider.";
          };
          startupCommand = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = "Provider startup command, or null when startup is systemd-owned.";
          };
          commands = lib.mkOption {
            type = lib.types.submodule {
              options = lib.genAttrs commandNames (_: lib.mkOption { type = lib.types.str; });
            };
          };
        };
      }
    );
    default = { };
    internal = true;
  };

  options.my.desktop.shellCommands = lib.mkOption {
    type = lib.types.submodule {
      options = {
        launcher = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        dashboard = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        settings = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        session = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
        lock = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };
    };
    default = { };
    internal = true;
    description = "Internal commands exposed by the selected desktop shell.";
  };

  options.my.desktop.shellStartupCommand = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    internal = true;
    description = "Startup command exposed by the selected shell; null for none or systemd-owned startup.";
  };

  config = {
    my.desktop.shellCommands = lib.mkIf selected commands;
    my.desktop.shellStartupCommand = lib.mkIf selected providers.${shell}.startupCommand;
    assertions = [
      {
        assertion = shell == "none" || lib.hasAttr shell providers;
        message = "my.desktop.shell must be \"none\" or the name of a registered shell provider";
      }
      {
        assertion = shell == "none" || !selected || lib.all (name: commands.${name} != "") commandNames;
        message = "The selected desktop shell provider must provide non-empty launcher, dashboard, settings, session, and lock commands";
      }
      {
        assertion =
          !selected
          || (
            waylandSessions != [ ]
            && lib.all (session: builtins.elem session providers.${shell}.supportedSessions) waylandSessions
          );
        message = "Desktop shell ${shell} must support every available Wayland session (${lib.concatStringsSep ", " waylandSessions}), but supports only ${
          lib.optionalString selected (lib.concatStringsSep ", " providers.${shell}.supportedSessions)
        }; i3 is an independent X11 alternative";
      }
      {
        assertion = !selected || providers.${shell}.startupCommand != "";
        message = "Desktop shell ${shell} startupCommand must be non-empty or null for systemd-owned startup";
      }
    ];
  };
}
