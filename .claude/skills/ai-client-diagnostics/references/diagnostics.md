# Commands and evidence

Run from the nix-config root. These commands inspect/build; they do not activate.
Review output before sharing: status and logs can contain project/session data.

## 1. Installed versus selected

```sh
command -v opencode
command -v claude
opencode --version
claude --version
nix eval --raw 'path:.#packages.aarch64-darwin.opencode.version'
```

Use `x86_64-linux` on Zaros. Inspect `flake.lock` for the locked `opencode` node; do not update it as a diagnostic step. The active CLI
version may lag the checkout until an approved activation.

## 2. Offline integration contract

```sh
system=$(nix eval --impure --raw --expr builtins.currentSystem)
nix build --no-link \
  "path:.#checks.${system}.ai-profile" \
  "path:.#checks.${system}.opencode-craft"
```

`modules/profiles/config/test-ai.nix` checks client composition. Test failures
should be traced to the first failing assertion or builder, rather than changing
live configuration.

## 3. Minimal isolated OpenCode package probe

This only invokes version/path diagnostics. It does not open a chat or validate
an existing database. Run the subshell as one command; it leaves its temporary
directory for inspection. On macOS use the harness-approved temp directory when
one is provided.

```sh
(
  set -eu
  system=$(nix eval --impure --raw --expr builtins.currentSystem)
  package=$(nix build --no-link --print-out-paths "path:.#packages.${system}.opencode")
  base=${TMPDIR:-/tmp}
  probe=$(mktemp -d "${base%/}/ai-client-probe.XXXXXX")
  export HOME="$probe/home"
  export XDG_CONFIG_HOME="$probe/config" XDG_DATA_HOME="$probe/data"
  export XDG_CACHE_HOME="$probe/cache" XDG_STATE_HOME="$probe/state"
  export OPENCODE_DISABLE_MODELS_FETCH=true OPENCODE_DISABLE_AUTOUPDATE=true
  export OPENCODE_CONFIG_PROJECT_DISABLE=true
  unset OPENCODE_CONFIG OPENCODE_CONFIG_CONTENT OPENCODE_CONFIG_DIR
  mkdir -p "$HOME" "$XDG_CONFIG_HOME/opencode" "$XDG_DATA_HOME" \
    "$XDG_CACHE_HOME" "$XDG_STATE_HOME"
  printf '%s\n' '{"disabled":true}' > "$XDG_CONFIG_HOME/opencode/service-prod.json"
  cd "$probe"
  "$package/bin/opencode" --version
  actual=$("$package/bin/opencode" debug paths db)
  printf 'Isolated DB path: %s\n' "$actual"
  test "$actual" = "$XDG_DATA_HOME/opencode/opencode.db"
)
```

This mirrors the pinned check, including its service-config filename. Recheck
that fixture after any upstream channel change. Do not reuse this probe to run
interactive clients with inherited credentials or connect it to the real home.
