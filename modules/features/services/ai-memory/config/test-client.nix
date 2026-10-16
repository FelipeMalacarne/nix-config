{
  lib,
  pkgs,
  home-manager,
  module,
  opencode,
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
            package = opencode;
          };
        }
      ];
    }).config;
  plugin = cfg.xdg.configFile."opencode/plugins/ai-memory-opencode2.ts".source;
  skills = lib.filterAttrs (name: _: lib.hasPrefix "opencode/skills/" name) cfg.xdg.configFile;
in
assert cfg.home.sessionVariables.AI_MEMORY_RUN_AUTOWIRE == "false";
assert cfg.home.shellAliases.oc == "ai-memory run --no-autowire opencode";
assert cfg.home.file.ai-memory-capture-mode.text == "allowlist\n";
assert lib.versions.major (lib.getVersion cfg.programs.opencode.package) == "2";
assert !(cfg.xdg.configFile ? "opencode/plugins/ai-memory.ts");
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
      opencode
    ];
  }
  ''
    export HOME="$TMPDIR/home"
    export AI_MEMORY_DATA_DIR="$TMPDIR/data"
    mkdir -p "$HOME" "$AI_MEMORY_DATA_DIR"
    export XDG_CONFIG_HOME="$TMPDIR/config"
    export XDG_DATA_HOME="$TMPDIR/xdg-data"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export XDG_STATE_HOME="$TMPDIR/state"
    export OPENCODE_DISABLE_MODELS_FETCH=true
    export OPENCODE_DISABLE_AUTOUPDATE=true
    export OPENCODE_CONFIG_PROJECT_DISABLE=true
    export OPENCODE_CONFIG=${cfg.xdg.configFile."opencode/opencode.json".source}
    mkdir -p "$XDG_CONFIG_HOME/opencode"
    cp ${pkgs.writeText "opencode-service-prod.json" ''{"disabled":true}''} \
      "$XDG_CONFIG_HOME/opencode/service-prod.json"
    case "$(opencode --version)" in
      "opencode v2."*) ;;
      *) exit 1 ;;
    esac
    test "$(opencode debug paths db)" = "$XDG_DATA_HOME/opencode/opencode.db"
    jq -e '.mcp["ai-memory"].type == "local" and
      (.mcp["ai-memory"].command | index("--no-session-id") != null) and
      (.commands["memory-finish"].subagent == false) and
      (.commands["memory-finish"].template | contains("--session-id")) and
      (has("command") | not)' \
      "$OPENCODE_CONFIG" > /dev/null
    timeout 60s opencode debug config > "$TMPDIR/config-entries.json"
    jq -e --arg path "$OPENCODE_CONFIG" '
      [.[] | select(.type == "document" and .path == $path) | .info] as $docs |
      ($docs | length) == 1 and ($docs[0] |
        .mcp.servers["ai-memory"].type == "local" and
        (.mcp.servers["ai-memory"].command | index("--no-session-id") != null) and
        .commands["memory-finish"].subagent == false and
        (.commands["memory-finish"].template | contains("--session-id")))
    ' "$TMPDIR/config-entries.json" > /dev/null
    grep -q 'const TOKEN: string | null = null' ${plugin}
    grep -q 'allowlist' ${plugin}
    grep -q 'setup: async' ${plugin}
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
