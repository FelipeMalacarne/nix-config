{
  config,
  inputs,
  lib,
  ...
}:
let
  # `skills` receives Home Manager's pkgs so a skill can be generated from the
  # tool it documents.
  publish =
    skills:
    { config, pkgs, ... }:
    let
      resolved = skills pkgs;
    in
    {
      programs.opencode.skills = lib.mkIf config.programs.opencode.enable resolved;
      programs.claude-code.skills = lib.mkIf config.programs.claude-code.enable resolved;
    };
in
{
  flake.modules.homeManager = {
    ai-skills = publish (pkgs: {
      ai-client-troubleshooting = ./skills/ai-client-troubleshooting;
      # Herdr ships its agent skill in the binary; generating it keeps the
      # skill in step with the installed CLI.
      herdr = pkgs.runCommand "herdr-skill" { } ''
        mkdir $out
        ${lib.getExe pkgs.herdr} --skill > $out/SKILL.md
      '';
    });
    # Optional user workflow: hosts select it independently of the AI profile.
    linear-issue-skill = publish (_: {
      linear-issue = ./skills/linear-issue;
    });
  };

  perSystem = { pkgs, ... }: {
    checks.ai-skills = import ./config/test-skills.nix {
      inherit pkgs;
      inherit (inputs) home-manager;
      registry = config.flake.modules.homeManager;
    };
  };
}
