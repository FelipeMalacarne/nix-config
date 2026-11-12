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
      imports = [ registry.homeManager.chromium ];

      programs.mcp = {
        enable = true;
        servers.playwright = {
          command = lib.getExe' pkgs.nodejs "npx";
          args = [
            "-y"
            "@playwright/mcp"
          ]
          ++ (
            if config.programs.chromium.enable then
              # Attach to the agent Chromium through the Playwright MCP Bridge
              # extension. The relay launches the browser to open its connect
              # page, so point it at the Nix package.
              [
                "--extension"
                "--executable-path"
                (lib.getExe config.programs.chromium.finalPackage)
              ]
            else
              # Without an agent browser, launch Playwright's own isolated Chromium.
              [
                "--browser"
                "chromium"
              ]
          );
        };
      };
    };
}
