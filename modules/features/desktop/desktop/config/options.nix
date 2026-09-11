{ config, lib, ... }:
let
  monitors = config.my.desktop.monitors;
  monitorList = lib.attrValues monitors;
  roles = map (monitor: monitor.role) monitorList;
  identifiers = lib.concatMap (monitor: [
    monitor.match.waylandDescription
    monitor.match.xrandrOutput
  ]) monitorList;
  workspaces = lib.concatMap (monitor: monitor.workspaces) monitorList;
in
{
  options.my.desktop.sessions = lib.mkOption {
    type = lib.types.listOf (
      lib.types.enum [
        "i3"
        "hyprland"
      ]
    );
    default = [
      "i3"
      "hyprland"
    ];
    description = "Desktop sessions made available on this system.";
  };

  options.my.desktop.shell = lib.mkOption {
    type = lib.types.str;
    default = "noctalia";
    description = "Registered desktop shell provider name, or none.";
  };

  options.my.desktop.monitors = lib.mkOption {
    default = { };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          role = lib.mkOption {
            type = lib.types.enum [
              "primary"
              "secondary"
            ];
          };
          match = lib.mkOption {
            type = lib.types.submodule {
              options = {
                waylandDescription = lib.mkOption { type = lib.types.str; };
                xrandrOutput = lib.mkOption { type = lib.types.str; };
              };
            };
          };
          mode = lib.mkOption {
            type = lib.types.submodule {
              options = {
                width = lib.mkOption { type = lib.types.ints.positive; };
                height = lib.mkOption { type = lib.types.ints.positive; };
                refresh = lib.mkOption { type = lib.types.numbers.positive; };
              };
            };
          };
          position = lib.mkOption {
            type = lib.types.submodule {
              options = {
                x = lib.mkOption { type = lib.types.int; };
                y = lib.mkOption { type = lib.types.int; };
              };
            };
          };
          rotation = lib.mkOption {
            type = lib.types.enum [
              0
              90
              180
              270
            ];
            default = 0;
          };
          scale = lib.mkOption {
            type = lib.types.numbers.positive;
            default = 1;
          };
          workspaces = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
      }
    );
  };

  config.assertions = [
    {
      assertion = config.my.desktop.sessions != [ ];
      message = "my.desktop.sessions must not be empty";
    }
    {
      assertion = lib.unique config.my.desktop.sessions == config.my.desktop.sessions;
      message = "my.desktop.sessions must contain unique values";
    }
    {
      assertion = monitorList == [ ] || lib.length (lib.filter (role: role == "primary") roles) == 1;
      message = "my.desktop.monitors must define exactly one primary monitor";
    }
    {
      assertion = lib.length (lib.unique identifiers) == lib.length identifiers;
      message = "my.desktop monitor identifiers must be unique";
    }
    {
      assertion = lib.length (lib.unique workspaces) == lib.length workspaces;
      message = "my.desktop monitor workspaces must be unique";
    }
    {
      assertion = lib.all (monitor: monitor.scale == 1) monitorList;
      message = "my.desktop monitor scale must be 1 for i3/XRandR-compatible topology";
    }
    {
      assertion =
        config.my.desktop.shell == "none" || builtins.elem "hyprland" config.my.desktop.sessions;
      message = "A selected desktop shell requires my.desktop.sessions to include hyprland; select shell = none or add hyprland";
    }
  ];
}
