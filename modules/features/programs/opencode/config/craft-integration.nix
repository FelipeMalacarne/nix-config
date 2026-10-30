{ lib, artcraft }:
let
  # The artcraft-flake module registers the craft-<app> MCP servers itself;
  # OpenCode only scopes them to the editor when that registration is active.
  enabled =
    artcraft != null && artcraft.mcp.enable && lib.any (app: app.enable) (lib.attrValues artcraft.apps);
in
{
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
