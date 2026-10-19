{ inputs, self, ... }:
{
  flake.modules.homeManager.github-mcp =
    { lib, pkgs, ... }:
    let
      launcher = pkgs.writeShellScript "github-mcp" ''
        set -euo pipefail
        if ! GITHUB_PERSONAL_ACCESS_TOKEN="$(${lib.getExe pkgs.gh} auth token --hostname github.com)" \
          || [[ -z "$GITHUB_PERSONAL_ACCESS_TOKEN" ]]; then
          echo 'GitHub MCP: run gh auth login --hostname github.com in a private terminal first.' >&2
          exit 1
        fi
        export GITHUB_PERSONAL_ACCESS_TOKEN
        exec ${lib.getExe pkgs.github-mcp-server} stdio
      '';
    in
    {
      programs.mcp = {
        enable = true;
        servers.github.command = toString launcher;
      };
    };

  perSystem = { lib, pkgs, ... }: {
    checks.github-mcp = import ./config/test.nix {
      inherit
        lib
        pkgs
        self
        inputs
        ;
    };
  };
}
