{ config, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.homeManager.playwright-mcp =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      key = "nix-config/homeManager/playwright-mcp";
      imports = [ registry.homeManager.chrome ];

      programs.mcp = {
        enable = true;
        servers.playwright = {
          command = lib.getExe' pkgs.nodejs "npx";
          # Attach to the logged-in Chrome through the Playwright MCP Bridge
          # extension. The relay launches the browser to open its connect page,
          # so point it at the Nix package instead of /opt/google/chrome.
          args = [
            "-y"
            "@playwright/mcp"
            "--extension"
            "--executable-path"
            (lib.getExe config.programs.google-chrome.finalPackage)
          ];
        };
      };
    };
}
