{
  config,
  inputs,
  self,
  ...
}:
let
  registry = config.flake.modules;
  workstation = platform: { config, ... }: {
    imports = [ registry.${platform}.ai-memory-client ];
    home-manager.users.${config.my.user.name}.imports = [ registry.homeManager.ai ];
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

  perSystem = { lib, pkgs, ... }: {
    checks.ai-profile = import ./config/test-ai.nix {
      inherit
        lib
        pkgs
        self
        inputs
        ;
    };
  };
}
