{ lib, apps }:
let
  selected = lib.filterAttrs (_: app: app.enable) apps;
  enabled = selected != { };
in
{
  # Reuse the host's package selection (including package overrides).
  # getExe would launch the GUI because that is each package's mainProgram.
  servers = lib.mapAttrs' (
    name: app:
    lib.nameValuePair "craft-${name}" {
      command = lib.getExe' app.package "${name}-cli";
      args = [
        "mcp"
      ];
      enabled = true;
    }
  ) selected;

  settings = lib.optionalAttrs enabled {
    # These are tool visibility rules, not a filesystem security sandbox.
    tools."craft-*" = false;
    agent.craft-editor = {
      description = "Edit media and documents with the selected Craft apps; inspect, save and verify real outputs.";
      mode = "subagent";
      prompt = builtins.readFile ../prompts/craft-editor.md;
      tools."craft-*" = true;
    };
  };

  skills = lib.optionalAttrs enabled {
    artcraft-editing = ../skills/artcraft-editing;
  };
}
