{
  lib,
  pkgs,
  home-manager,
  module,
}:
let
  cfg =
    (home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        module
        {
          home.username = "memory-check";
          home.homeDirectory = "/tmp/memory-check";
          home.stateVersion = "24.11";
          my.ai.memory.client.serverUrl = "https://memory.example.test:8443";
          my.ai.memory.client.tokenFile = "/run/secrets/ai-memory-token";
          programs.opencode = {
            enable = true;
            enableMcpIntegration = true;
            package = pkgs.writeShellScriptBin "opencode" "exit 0";
          };
        }
      ];
    }).config;
  plugin = cfg.xdg.configFile."opencode/plugins/ai-memory-opencode2.ts".source;
  skills = lib.filterAttrs (name: _: lib.hasPrefix "opencode/skills/" name) cfg.xdg.configFile;
in
assert cfg.home.sessionVariables.AI_MEMORY_RUN_AUTOWIRE == "false";
assert cfg.home.file.ai-memory-capture-mode.text == "allowlist\n";
assert !cfg.programs.opencode.settings.commands.memory-finish.subagent;
assert lib.hasInfix "--session-id" cfg.programs.opencode.settings.commands.memory-finish.template;
assert lib.hasInfix "$ARGUMENTS" cfg.programs.opencode.settings.commands.memory-finish.template;
assert
  cfg.programs.mcp.servers.ai-memory.args == [
    "--data-dir"
    (
      if pkgs.stdenv.hostPlatform.isDarwin then
        "/tmp/memory-check/Library/Application Support/ai-memory"
      else
        "/tmp/memory-check/.local/share/ai-memory"
    )
    "mcp-bridge"
    "--no-session-id"
    "--server-url"
    "https://memory.example.test:8443"
  ];
assert
  builtins.attrNames skills == [
    "opencode/skills/ai-memory-durable-pages"
    "opencode/skills/ai-memory-handoff"
    "opencode/skills/ai-memory-retrieval"
  ];
assert cfg.programs.opencode.skills == { };
pkgs.runCommand "ai-memory-client"
  {
    nativeBuildInputs = [
      pkgs.nodejs
      pkgs.jq
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    export AI_MEMORY_DATA_DIR="$TMPDIR/data"
    mkdir -p "$HOME" "$AI_MEMORY_DATA_DIR"
    jq -e '.mcp["ai-memory"].type == "local" and
      (.mcp["ai-memory"].command | index("--no-session-id") != null) and
      (.commands["memory-finish"].subagent == false) and
      (.commands["memory-finish"].template | contains("--session-id"))' \
      ${cfg.xdg.configFile."opencode/opencode.json".source} > /dev/null
    grep -q 'const TOKEN: string | null = null' ${plugin}
    grep -q 'allowlist' ${plugin}
    test "$(readlink ${cfg.home.file.ai-memory-auth-token.source})" = /run/secrets/ai-memory-token
    for skill in ${
      lib.concatMapStringsSep " " (skill: lib.escapeShellArg (toString skill.source)) (
        lib.attrValues skills
      )
    }; do
      test -f "$skill/SKILL.md"
    done
    grep -q 'expected_page_id' ${skills."opencode/skills/ai-memory-durable-pages".source}/SKILL.md
    if grep -q 'There is no patch or compare-and-write precondition' ${
      skills."opencode/skills/ai-memory-durable-pages".source
    }/SKILL.md; then
      echo 'Durable-page concurrency guidance regressed' >&2
      exit 1
    fi
    node ${./test-spool-limits.mjs} ${plugin}
    node --experimental-strip-types ${./test-offline.mjs} ${plugin}
    touch "$out"
  ''
