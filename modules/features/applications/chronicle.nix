{ config, inputs, ... }:
let
  registry = config.flake.modules;
in
{
  # Chronicle's CLI, MCP server and Microbot agent (github:FelipeMalacarne/chronicle):
  # `chronicle login`, `accounts connect`, `workers`, `mcp` and `agent`. Packaging and
  # its vendorHash live in that flake; the server itself runs on saradomin.
  flake.modules.homeManager.chronicle =
    { pkgs, ... }:
    {
      home.packages = [ inputs.chronicle.packages.${pkgs.stdenv.hostPlatform.system}.chronicle ];
    };

  perSystem =
    { evalHome, mkAssertCheck, ... }:
    let
      names = cfg: map (p: p.pname or (builtins.parseDrvName p.name).name) cfg.home.packages;
    in
    {
      checks.chronicle = mkAssertCheck "chronicle-composition" [
        {
          assertion = !(builtins.elem "chronicle" (names (evalHome [ ])));
          message = "Chronicle must not be installed without importing its aspect.";
        }
        {
          assertion = builtins.elem "chronicle" (names (evalHome [ registry.homeManager.chronicle ]));
          message = "Importing the chronicle aspect must install its CLI.";
        }
      ];
    };
}
