{ config, lib, ... }:
let
  sessionType = lib.types.enum [
    "i3"
    "hyprland"
    "umbriel"
  ];
  monitors = config.my.desktop.monitors;
  x11 = builtins.elem "i3" config.my.desktop.sessions;
  wayland = lib.any (session: builtins.elem session config.my.desktop.sessions) [
    "hyprland"
    "umbriel"
  ];
  monitorList = lib.attrValues monitors;
  roles = map (monitor: monitor.role) monitorList;
  identifiers = lib.filter (identifier: identifier != null) (
    lib.concatMap (
      monitor:
      lib.optional wayland monitor.match.waylandDescription ++ lib.optional x11 monitor.match.xrandrOutput
    ) monitorList
  );
  workspaces = lib.concatMap (monitor: monitor.workspaces) monitorList;
in
{
  options.my.desktop.sessions = lib.mkOption {
    type = lib.types.listOf sessionType;
    default = [
      "i3"
      "hyprland"
    ];
    description = "Desktop sessions made available on this system.";
  };

  options.my.desktop.defaultSession = lib.mkOption {
    type = sessionType;
    default =
      if builtins.elem "hyprland" config.my.desktop.sessions then
        "hyprland"
      else if config.my.desktop.sessions != [ ] then
        builtins.head config.my.desktop.sessions
      else
        "hyprland";
    defaultText = lib.literalExpression "Hyprland when available, otherwise the first selected session";
    description = "Default desktop session; must be one of my.desktop.sessions.";
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
            default = { };
            type = lib.types.submodule {
              options = {
                waylandDescription = lib.mkOption {
                  type = lib.types.nullOr lib.types.nonEmptyStr;
                  default = null;
                  description = "Required when a Wayland session is selected. Umbriel requires the full make, model, and serial, not a description prefix.";
                };
                xrandrOutput = lib.mkOption {
                  type = lib.types.nullOr lib.types.nonEmptyStr;
                  default = null;
                  description = "XRandR connector name, required only when i3 is selected.";
                };
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
      assertion = !wayland || lib.all (monitor: monitor.match.waylandDescription != null) monitorList;
      message = "my.desktop monitors require a Wayland description when hyprland or umbriel is selected";
    }
    {
      assertion = !x11 || lib.all (monitor: monitor.match.xrandrOutput != null) monitorList;
      message = "my.desktop monitors require an XRandR output when i3 is selected";
    }
    {
      assertion = config.my.desktop.sessions != [ ];
      message = "my.desktop.sessions must not be empty";
    }
    {
      assertion = lib.unique config.my.desktop.sessions == config.my.desktop.sessions;
      message = "my.desktop.sessions must contain unique values";
    }
    {
      assertion = builtins.elem config.my.desktop.defaultSession config.my.desktop.sessions;
      message = "my.desktop.defaultSession must be a member of my.desktop.sessions";
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
      assertion = !x11 || lib.all (monitor: monitor.scale == 1) monitorList;
      message = "my.desktop monitor scale must be 1 for i3/XRandR-compatible topology";
    }
    {
      assertion =
        config.my.desktop.shell == "none"
        || lib.any (session: builtins.elem session config.my.desktop.sessions) [
          "hyprland"
          "umbriel"
        ];
      message = "A selected desktop shell requires an available Wayland session (hyprland or umbriel); select shell = none for an X11-only desktop";
    }
  ];
}
