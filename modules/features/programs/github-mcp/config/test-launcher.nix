{
  lib,
  pkgs,
  self,
  inputs,
}:
let
  evaluate =
    modules:
    (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = modules ++ [
        {
          home.username = "github-mcp-check";
          home.homeDirectory = "/tmp/github-mcp-check";
          home.stateVersion = "24.11";
        }
      ];
    }).config;
  absent = evaluate [ ];
  selected = evaluate [ self.modules.homeManager.github-mcp ];
  launcher = selected.programs.mcp.servers.github.command;
  mockGh = pkgs.writeShellScript "mock-gh" ''
    set -euo pipefail
    test "$*" = 'auth token --hostname github.com'
    case "$MOCK_AUTH" in
      success) printf '%s\n' 'fixture-token-not-a-credential' ;;
      empty) exit 0 ;;
      failure) exit 1 ;;
    esac
  '';
  mockServer = pkgs.writeShellScript "mock-github-mcp" ''
    set -euo pipefail
    test "$*" = stdio
    test "$GITHUB_PERSONAL_ACCESS_TOKEN" = fixture-token-not-a-credential
    touch "$SERVER_STARTED"
  '';
in
assert !(absent.programs.mcp.servers ? github);
assert selected.programs.mcp.enable;
assert builtins.attrNames selected.programs.mcp.servers == [ "github" ];
assert !(selected.programs.opencode.enable or false);
assert !(selected.programs.claude-code.enable or false);
assert selected.programs.mcp.servers.github.env == { };
assert selected.programs.mcp.servers.github.url == null;
pkgs.runCommand "github-mcp" { } ''
  export HOME="$TMPDIR/home"
  export XDG_CONFIG_HOME="$TMPDIR/config"
  mkdir -p "$HOME" "$XDG_CONFIG_HOME"
  substitute ${launcher} "$TMPDIR/launcher" \
    --replace-fail ${lib.getExe pkgs.gh} ${mockGh} \
    --replace-fail ${lib.getExe pkgs.github-mcp-server} ${mockServer}
  chmod +x "$TMPDIR/launcher"
  export SERVER_STARTED="$TMPDIR/started"
  export GITHUB_PERSONAL_ACCESS_TOKEN=stale-fixture-token
  export MOCK_AUTH=success
  "$TMPDIR/launcher" > "$TMPDIR/stdout" 2> "$TMPDIR/stderr"
  test -f "$SERVER_STARTED"
  test ! -s "$TMPDIR/stdout"
  test ! -s "$TMPDIR/stderr"
  rm "$SERVER_STARTED"
  for MOCK_AUTH in failure empty; do
    export MOCK_AUTH
    if "$TMPDIR/launcher" > "$TMPDIR/stdout" 2> "$TMPDIR/stderr"; then
      echo 'GitHub MCP must refuse missing authentication' >&2
      exit 1
    fi
    test ! -e "$SERVER_STARTED"
    test ! -s "$TMPDIR/stdout"
    grep -Fq 'gh auth login --hostname github.com' "$TMPDIR/stderr"
    if grep -Fq 'fixture-token' "$TMPDIR/stderr"; then
      echo 'GitHub MCP must not log credentials' >&2
      exit 1
    fi
  done
  touch "$out"
''
