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
    { pkgs, ... }:
    {
      checks.chronicle = import ./config/test.nix {
        inherit pkgs;
        inherit (inputs) home-manager;
        module = registry.homeManager.chronicle;
      };
    };
}
