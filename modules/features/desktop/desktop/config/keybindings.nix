{
  config,
  lib,
  pkgs,
  ...
}:
let
  terminal = config.my.desktop.terminalCommand;
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
    description = "Terminal executable used by desktop application bindings; must support -e and --working-directory. Override terminalDesktopId alongside it.";
  };
  options.my.desktop.terminalDesktopId = lib.mkOption {
    type = lib.types.str;
    internal = true;
    description = "Desktop entry ID corresponding to terminalCommand, used by application integrations.";
  };
  options.my.desktop.applicationBindings = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          command = lib.mkOption { type = lib.types.str; };
          key = lib.mkOption { type = lib.types.str; };
          modifiers = lib.mkOption {
            type = lib.types.listOf (
              lib.types.enum [
                "shift"
                "control"
                "alt"
              ]
            );
          };
        };
      }
    );
    internal = true;
    readOnly = true;
    description = "Shared application bindings with terminal wrapping but no session-manager prefix; the compositor supplies Mod.";
  };
  config = {
    my.desktop.terminalCommand = lib.mkDefault (lib.getExe config.programs.ghostty.package);
    my.desktop.terminalDesktopId = lib.mkDefault "com.mitchellh.ghostty.desktop";
    my.desktop.applicationBindings = lib.mapAttrs (_: binding: {
      inherit (binding) key modifiers;
      command =
        if binding.inTerminal or false then "${terminal} -e ${binding.command}" else binding.command;
    }) bindings;
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
}
