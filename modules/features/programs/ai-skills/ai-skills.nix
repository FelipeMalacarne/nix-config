{
  flake.modules.homeManager.ai-skills =
    { config, lib, ... }:
    let
      skills.ai-client-troubleshooting = ./skills/ai-client-troubleshooting;
    in
    {
      programs.opencode.skills = lib.mkIf config.programs.opencode.enable skills;
      programs.claude-code.skills = lib.mkIf config.programs.claude-code.enable skills;
    };
}
