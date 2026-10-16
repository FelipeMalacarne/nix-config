{
  flake.modules.homeManager.playwright-mcp =
    {
      lib,
      pkgs,
      ...
    }:
    {
      programs.mcp = {
        enable = true;
        servers.playwright = {
          command = lib.getExe' pkgs.nodejs "npx";
          args = [
            "-y"
            "@playwright/mcp"
          ];
        };
      };
    };
}
