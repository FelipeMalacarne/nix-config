{ inputs, self, ... }:
{
  flake.modules.homeManager.linear-mcp = {
    programs.mcp = {
      enable = true;
      servers.linear.url = "https://mcp.linear.app/mcp";
    };
  };

  perSystem =
    { pkgs, ... }:
    let
      evaluate =
        modules:
        (inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = modules ++ [
            {
              home.username = "linear-mcp-check";
              home.homeDirectory = "/tmp/linear-mcp-check";
              home.stateVersion = "24.11";
            }
          ];
        }).config;
      absent = evaluate [ ];
      selected = evaluate [ self.modules.homeManager.linear-mcp ];
    in
    {
      checks.linear-mcp =
        assert !(absent.programs.mcp.servers ? linear);
        assert selected.programs.mcp.enable;
        assert builtins.attrNames selected.programs.mcp.servers == [ "linear" ];
        assert selected.programs.mcp.servers.linear.url == "https://mcp.linear.app/mcp";
        assert selected.programs.mcp.servers.linear.command == null;
        assert selected.programs.mcp.servers.linear.headers == { };
        assert !(selected.programs.opencode.enable or false);
        assert !(selected.programs.claude-code.enable or false);
        pkgs.runCommand "linear-mcp" { } "touch $out";
    };
}
