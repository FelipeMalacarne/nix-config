{
  config,
  inputs,
  secretsDir,
  self,
  ...
}:
let
  registry = config.flake.modules;
  workstation = {
    home-manager.sharedModules = [ registry.homeManager.ai ];
  };
in
{
  flake.modules.nixos.ai = workstation;
  flake.modules.darwin.ai = workstation;
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
