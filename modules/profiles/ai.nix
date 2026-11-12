{
  config,
  inputs,
  secretsDir,
  self,
  ...
}:
let
  registry = config.flake.modules;
  workstation = platform: {
    imports = [ registry.${platform}.ai-memory-client ];
    home-manager.sharedModules = [ registry.homeManager.ai ];
  };
in
{
  flake.modules.nixos.ai = workstation "nixos";
  flake.modules.darwin.ai = workstation "darwin";
  flake.modules.homeManager.ai = {
    imports = with registry.homeManager; [
      opencode
      claude-code
      codex
      github-copilot-cli
    ];
  };

  perSystem =
    {
      lib,
      pkgs,
      evalHome,
      ...
    }:
    {
      checks.ai-profile = import ./config/test-ai.nix {
        inherit
          lib
          pkgs
          self
          inputs
          evalHome
          secretsDir
          ;
      };
    };
}
