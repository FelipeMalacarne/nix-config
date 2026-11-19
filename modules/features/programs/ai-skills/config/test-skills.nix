{
  pkgs,
  home-manager,
  registry,
}:
let
  evaluate =
    modules:
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = modules ++ [
        {
          home.username = "ai-skills-check";
          home.homeDirectory = "/tmp/ai-skills-check";
          home.stateVersion = "24.11";
        }
      ];
    }).config;
  claudeClient.programs.claude-code = {
    enable = true;
    package = pkgs.writeShellScriptBin "claude" "exit 0";
  };
  opencodeClient.programs.opencode = {
    enable = true;
    package = pkgs.writeShellScriptBin "opencode" "exit 0";
  };
  absent = evaluate [ ];
  unselected = evaluate [
    registry.ai-skills
    claudeClient
    opencodeClient
  ];
  skillOnly = evaluate [ registry.linear-issue-skill ];
  claude = evaluate [
    registry.linear-issue-skill
    claudeClient
  ];
  opencode = evaluate [
    registry.linear-issue-skill
    opencodeClient
  ];
  both = evaluate [
    registry.ai-skills
    registry.linear-issue-skill
    claudeClient
    opencodeClient
  ];
  source = ../skills/linear-issue;
  python = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
in
assert !(absent.programs.claude-code.skills ? linear-issue);
assert !(absent.programs.opencode.skills ? linear-issue);
assert !(unselected.programs.claude-code.skills ? linear-issue);
assert !(unselected.programs.opencode.skills ? linear-issue);
assert !skillOnly.programs.claude-code.enable && !skillOnly.programs.opencode.enable;
assert skillOnly.programs.claude-code.skills == { } && skillOnly.programs.opencode.skills == { };
assert !claude.programs.opencode.enable && !opencode.programs.claude-code.enable;
assert claude.programs.claude-code.skills.linear-issue == source;
assert opencode.programs.opencode.skills.linear-issue == source;
assert both.programs.claude-code.skills == both.programs.opencode.skills;
assert
  builtins.attrNames both.programs.claude-code.skills == [
    "ai-client-troubleshooting"
    "herdr"
    "linear-issue"
  ];
pkgs.runCommand "ai-skills" { } ''
  cmp ${source}/SKILL.md ${both.home-files}/.claude/skills/linear-issue/SKILL.md
  cmp ${source}/SKILL.md ${both.home-files}/.config/opencode/skills/linear-issue/SKILL.md
  ${python}/bin/python3 -B - ${source}/SKILL.md <<'PY'
  from pathlib import Path
  import sys
  import yaml

  text = Path(sys.argv[1]).read_text()
  _, frontmatter, body = text.split("---", 2)
  metadata = yaml.safe_load(frontmatter)
  assert metadata["name"] == "linear-issue"
  assert isinstance(metadata["description"], str) and metadata["description"]
  assert metadata["argument-hint"] == "[brief context of the task]"
  assert "score_issue = (complexidade * 0.70)" in body
  assert "Portuguese (pt-BR)" in body
  PY
  touch "$out"
''
