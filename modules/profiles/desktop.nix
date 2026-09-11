{ self, lib, ... }:
let
  desktopOptions =
    { config, ... }:
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
      ];
    };

  desktopKeybindings =
    { config, pkgs, ... }:
    let
      terminal = lib.getExe config.programs.ghostty.package;
      uwsm = lib.getExe pkgs.uwsm;
      fastfetchPause = pkgs.writeShellApplication {
        name = "fastfetch-pause";
        runtimeInputs = [ pkgs.fastfetch ];
        text = ''
          fastfetch
          read -r -p "Press enter to close..."
        '';
      };
      bindings = {
        yazi = {
          command = lib.getExe config.programs.yazi.package;
          key = "f";
          modifiers = [ "shift" ];
          inTerminal = true;
        };
        btop = {
          command = lib.getExe config.programs.btop.package;
          key = "t";
          modifiers = [ "shift" ];
          inTerminal = true;
        };
        fastfetch = {
          command = lib.getExe fastfetchPause;
          key = "i";
          modifiers = [ "shift" ];
          inTerminal = true;
        };
        firefox = {
          command = lib.getExe config.programs.firefox.package;
          key = "b";
          modifiers = [ "shift" ];
        };
      };
      i3Bindings = builtins.listToAttrs (
        map (
          binding:
          let
            modifierNames = {
              shift = "Shift";
              control = "Control";
              alt = "Mod1";
            };
            key = lib.concatStringsSep "+" (
              [ "Mod4" ] ++ map (modifier: modifierNames.${modifier}) binding.modifiers ++ [ binding.key ]
            );
            command =
              if binding.inTerminal or false then "${terminal} -e ${binding.command}" else binding.command;
          in
          {
            name = key;
            value = "exec ${command}";
          }
        ) (lib.attrValues bindings)
      );
      sharedBindingsLua = lib.concatMapStringsSep "\n" (
        binding:
        let
          key = lib.concatStringsSep " + " (
            [ "SUPER" ] ++ map lib.toUpper binding.modifiers ++ [ (lib.toUpper binding.key) ]
          );
          command = "${uwsm} app -- ${
            if binding.inTerminal or false then "${terminal} -e ${binding.command}" else binding.command
          }";
        in
        "hl.bind(${builtins.toJSON key}, hl.dsp.exec_cmd(${builtins.toJSON command}))"
      ) (lib.attrValues bindings);
    in
    {
      options.my.desktop.terminalCommand = lib.mkOption {
        type = lib.types.str;
        internal = true;
        description = "Terminal executable used by desktop application bindings.";
      };

      config = {
        my.desktop.terminalCommand = lib.mkDefault terminal;
        xsession.windowManager.i3.config = lib.mkIf (builtins.elem "i3" config.my.desktop.sessions) {
          keybindings = i3Bindings;
          terminal = terminal;
        };
        wayland.windowManager.hyprland.extraLuaFiles.sharedBindings =
          lib.mkIf (builtins.elem "hyprland" config.my.desktop.sessions)
            {
              content = sharedBindingsLua;
              autoLoad = true;
            };
      };
    };
in
{
  flake.nixosModules.desktop =
    { config, ... }:
    {
      imports = [
        self.nixosModules.audio
        self.nixosModules.network
        self.nixosModules.sddm
        self.nixosModules.i3
        self.nixosModules.hyprland
        self.nixosModules.noctalia
        self.nixosModules.firefox
        self.nixosModules.dolphin
        self.nixosModules.kdeconnect
        desktopOptions
      ];
      config.home-manager.users.${config.my.user.name} = {
        my.desktop.sessions = config.my.desktop.sessions;
        my.desktop.monitors = config.my.desktop.monitors;
      };
    };

  flake.homeModules.desktop = {
    imports = with self.homeModules; [
      desktopOptions
      desktopKeybindings
      i3
      hyprland
      noctalia
      firefox
      dolphin
      ghostty
      kdeconnect
      bitwarden
    ];
  };
}
