{ config, inputs, ... }:
let
  publish =
    skills:
    { config, lib, ... }:
    {
      programs.opencode.skills = lib.mkIf config.programs.opencode.enable skills;
      programs.claude-code.skills = lib.mkIf config.programs.claude-code.enable skills;
    };
in
{
  flake.modules.homeManager = {
    ai-skills = publish {
      ai-client-troubleshooting = ./skills/ai-client-troubleshooting;
    };
    # Optional user workflow: hosts select it independently of the AI profile.
    linear-issue-skill = publish {
      linear-issue = ./skills/linear-issue;
    };
  };

  perSystem = { pkgs, ... }: {
    checks.ai-skills = import ./config/test-skills.nix {
      inherit pkgs;
      inherit (inputs) home-manager;
      registry = config.flake.modules.homeManager;
    };
  };
}
