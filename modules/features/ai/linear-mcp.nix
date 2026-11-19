{ self, ... }:
{
  flake.modules.homeManager.linear-mcp = {
    programs.mcp = {
      enable = true;
      servers.linear.url = "https://mcp.linear.app/mcp";
    };
  };

  perSystem =
    { evalHome, mkAssertCheck, ... }:
    let
      absent = evalHome [ ];
      selected = evalHome [ self.modules.homeManager.linear-mcp ];
      server = selected.programs.mcp.servers.linear;
    in
    {
      checks.linear-mcp = mkAssertCheck "linear-mcp" [
        {
          assertion = !(absent.programs.mcp.servers ? linear);
          message = "Linear MCP must not be registered without importing its aspect.";
        }
        {
          assertion =
            selected.programs.mcp.enable && builtins.attrNames selected.programs.mcp.servers == [ "linear" ];
          message = "Importing linear-mcp must register only the Linear server in the shared MCP registry.";
        }
        {
          assertion =
            server.url == "https://mcp.linear.app/mcp" && server.command == null && server.headers == { };
          message = "Linear must use its official remote endpoint with client-managed OAuth, no local command or static headers.";
        }
        {
          assertion =
            !(selected.programs.opencode.enable or false) && !(selected.programs.claude-code.enable or false);
          message = "The MCP aspect must not enable any client by itself.";
        }
      ];
    };
}
