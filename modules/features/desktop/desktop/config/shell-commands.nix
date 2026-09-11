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
in
{
  options.my.desktop.shellProviders = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options.commands = lib.mkOption {
          type = lib.types.submodule {
            options = lib.genAttrs commandNames (_: lib.mkOption { type = lib.types.str; });
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

  config = {
    my.desktop.shellCommands = lib.mkIf selected commands;
    assertions = [
      {
        assertion = shell == "none" || lib.hasAttr shell providers;
        message = "my.desktop.shell must be \"none\" or the name of a registered shell provider";
      }
      {
        assertion = shell == "none" || !selected || lib.all (name: commands.${name} != "") commandNames;
        message = "The selected desktop shell provider must provide non-empty launcher, dashboard, settings, session, and lock commands";
      }
    ];
  };
}
