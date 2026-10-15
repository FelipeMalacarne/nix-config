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
          my.ai-memory.serverUrl = "https://memory.example.test:8443";
          my.ai-memory.tokenFile = "/run/secrets/ai-memory-token";
          programs.opencode = {
            enable = true;
            enableMcpIntegration = true;
            package = pkgs.writeShellScriptBin "opencode" "exit 0";
          };
        }
      ];
    }).config;
  plugin = cfg.xdg.configFile."opencode/plugins/ai-memory-opencode2.ts".source;
in
assert cfg.home.sessionVariables.AI_MEMORY_RUN_AUTOWIRE == "false";
assert cfg.home.file.ai-memory-capture-mode.text == "allowlist\n";
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
  builtins.attrNames cfg.programs.opencode.skills == [
    "ai-memory-durable-pages"
    "ai-memory-handoff"
    "ai-memory-retrieval"
  ];
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
      (.mcp["ai-memory"].command | index("--no-session-id") != null)' \
      ${cfg.xdg.configFile."opencode/opencode.json".source} > /dev/null
    grep -q 'const TOKEN: string | null = null' ${plugin}
    grep -q 'allowlist' ${plugin}
    test "$(readlink ${cfg.home.file.ai-memory-auth-token.source})" = /run/secrets/ai-memory-token
    for skill in ${lib.concatStringsSep " " (lib.attrValues cfg.programs.opencode.skills)}; do
      test -f "$skill/SKILL.md"
    done
    node --experimental-strip-types ${./test-offline.mjs} ${plugin}
    touch "$out"
  ''
