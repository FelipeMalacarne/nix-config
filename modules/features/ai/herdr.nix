{ config, ... }:
let
  registry = config.flake.modules.homeManager;
in
{
  flake.modules.homeManager.herdr =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      herdr = config.programs.herdr.package;
      claude = config.programs.claude-code;
      skill = "${herdr}/share/skills/herdr/herdr";
      # Herdr's bundled Claude integration with python3 pinned: upstream skips
      # session reporting silently when python3 is missing from PATH.
      claudeHook = pkgs.runCommand "herdr-claude-hook" { } ''
        substitute ${herdr}/share/herdr/integrations/claude/herdr-agent-state.sh $out \
          --replace-fail python3 ${pkgs.python3}/bin/python3
      '';
      rules = ''
        # Herdr

        When `HERDR_ENV` is `1`, this session runs inside a Herdr pane.

        - Create git worktrees with
          `herdr worktree create --cwd <repo> --branch <branch> --no-focus`,
          never with `git worktree add`. Herdr places them under
          `~/.herdr/worktrees/` and opens a workspace for each. Remove one with
          `herdr worktree remove --workspace <id>`.
        - Run processes that must outlive the turn, such as dev servers and
          watchers, in a sibling pane: `herdr pane split --current --no-focus`,
          then `herdr pane run`.
        - Read the `herdr` skill before any other Herdr command.
      '';
      # Claude's WorktreeCreate hook skips worktrees made through Bash, so the
      # rule is enforced on the Bash call instead.
      worktreeGuard = pkgs.writeShellScript "herdr-worktree-guard" ''
        [ "''${HERDR_ENV:-}" = 1 ] || exit 0
        ${lib.getExe pkgs.jq} -r '.tool_input.command // ""' |
          ${lib.getExe pkgs.gnugrep} -Eq '\bgit\b.*\bworktree[[:space:]]+add\b' || exit 0
        ${lib.getExe pkgs.jq} -n '{
          hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: "Inside Herdr, create worktrees with `herdr worktree create --cwd <repo> --branch <branch> --no-focus` instead of `git worktree add`."
          }
        }'
      '';
    in
    {
      programs.herdr = {
        enable = true;
        # Onboarding and the settings panel write config.toml; activation merges
        # the declared values back over it.
        mutableSettings = true;
        settings = {
          onboarding = false;
          # Follow the Stylix-themed terminal palette.
          theme.name = "terminal";
          # Nix pins the binary, so upstream update notices cannot be acted on.
          update.version_check = false;
          # Desktop notifications through the outer terminal, also over SSH.
          ui.toast.delivery = "terminal";
          # Keys for actions Herdr leaves unset, avoiding the us(intl) dead keys
          # (' " ` ~ ^). A declared key that matches another action's default
          # disables that default silently; checks.herdr-integration rejects it.
          keys = {
            last_pane = "prefix+;";
            next_agent = "prefix+a";
            previous_agent = "prefix+shift+a";
            # Hyprland moves between workspaces with SUPER+[ and SUPER+].
            previous_workspace = "prefix+{";
            next_workspace = "prefix+}";
            move_tab_previous = "prefix+<";
            move_tab_next = "prefix+>";
            open_worktree = "prefix+shift+o";
            clear_pane = "prefix+shift+c";
            # Direct chords repeat while held; prefix+r stays as resize mode.
            resize_pane_left = "ctrl+alt+shift+left";
            resize_pane_down = "ctrl+alt+shift+down";
            resize_pane_up = "ctrl+alt+shift+up";
            resize_pane_right = "ctrl+alt+shift+right";
            # Matches the Neovim <leader>| split.
            split_vertical = [
              "prefix+v"
              "prefix+|"
            ];
            command = [
              {
                key = "prefix+t";
                type = "popup";
                command = "exec \"\${SHELL:-sh}\"";
                description = "scratch shell";
                width = "80%";
                height = "80%";
              }
              {
                key = "prefix+ctrl+g";
                type = "popup";
                command = "lazygit";
                description = "lazygit";
                width = "90%";
                height = "90%";
              }
            ];
          };
        };
      };

      programs.opencode = lib.mkIf config.programs.opencode.enable {
        skills.herdr = skill;
        context = rules;
      };

      # Mirrors `herdr integration install claude`: the same hook path and entry
      # keep `herdr integration status` current and a reinstall from duplicating it.
      programs.claude-code = lib.mkIf claude.enable {
        skills.herdr = skill;
        rules.herdr = rules;
        hooks."herdr-agent-state.sh" = claudeHook;
        hooks."herdr-worktree-guard.sh" = worktreeGuard;
        settings.hooks.PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "bash '${claude.configDir}/hooks/herdr-worktree-guard.sh'";
                timeout = 10;
              }
            ];
          }
        ];
        settings.hooks.SessionStart = [
          {
            matcher = "^(startup|resume|clear|compact|fork)$";
            hooks = [
              {
                type = "command";
                command = "bash '${claude.configDir}/hooks/herdr-agent-state.sh' session";
                timeout = 10;
              }
            ];
          }
        ];
      };
    };

  perSystem =
    {
      lib,
      pkgs,
      evalHome,
      mkAssertCheck,
      ...
    }:
    let
      claudeClient.programs.claude-code = {
        enable = true;
        package = pkgs.writeShellScriptBin "claude" "exit 0";
      };
      opencodeClient.programs.opencode = {
        enable = true;
        package = pkgs.writeShellScriptBin "opencode" "exit 0";
      };
      absent = evalHome [ ];
      alone = evalHome [ registry.herdr ];
      withClaude = evalHome [
        registry.herdr
        claudeClient
      ];
      withOpencode = evalHome [
        registry.herdr
        opencodeClient
      ];
      hooksDir = "${withClaude.programs.claude-code.configDir}/hooks";
      hookPath = "${hooksDir}/herdr-agent-state.sh";
      settings = (pkgs.formats.toml { }).generate "herdr-config.toml" alone.programs.herdr.settings;
      jq = lib.getExe pkgs.jq;
      declaredKeys = pkgs.writeText "herdr-keys.json" (
        builtins.toJSON alone.programs.herdr.settings.keys
      );
      keyReference = "${alone.programs.herdr.package.src}/docs/next/website/src/data/config-reference.json";
      # Herdr registers declared keys before its defaults and skips a default
      # whose key is taken without a diagnostic, so `herdr config check` passes.
      shadowedDefaults = pkgs.writeText "herdr-shadowed-defaults.jq" ''
        def list: if type == "array" then . else [.] end;
        def norm: split("+") | (.[-1] |= if test("^[A-Z]$") then "shift+" + ascii_downcase else . end) | join("+");
        $declared[0] as $keys
        | ($keys | del(.command, .prefix)) as $fields
        | [
            ($fields | to_entries[] | {field: .key, key: (.value | list[] | norm)}),
            (($keys.command // [])[] | {field: "command \(.key)", key: (.key | norm)})
          ] as $taken
        | $reference[0].sections[] | select(.id == "keys") | .keys[]
        | select(.default != "unset" and .key != "keys.prefix")
        | (.key | ltrimstr("keys.")) as $field
        | select($fields | has($field) | not)
        | (.default | fromjson | list[] | norm) as $key
        | $taken[] | select(.key == $key)
        | "\(.field) takes \($key) and silently disables the default \($field)"
      '';
      shadowed =
        declared:
        "${jq} -rn --slurpfile declared ${declared} --slurpfile reference ${keyReference} -f ${shadowedDefaults}";
    in
    {
      checks.herdr = mkAssertCheck "herdr" [
        {
          assertion = !absent.programs.herdr.enable;
          message = "Herdr must stay disabled unless the aspect is imported.";
        }
        {
          assertion = alone.programs.herdr.enable && !alone.programs.claude-code.enable;
          message = "Importing herdr must enable Herdr without enabling Claude Code.";
        }
        {
          assertion = alone.programs.claude-code.skills == { } && alone.programs.opencode.skills == { };
          message = "Herdr must not publish skills to clients that are not enabled.";
        }
        {
          assertion = withClaude.programs.claude-code.skills ? herdr;
          message = "Herdr must publish its skill to an enabled Claude Code.";
        }
        {
          assertion = alone.programs.claude-code.rules == { } && alone.programs.opencode.context == "";
          message = "Herdr must not publish its rule to clients that are not enabled.";
        }
        {
          assertion =
            lib.hasInfix "herdr worktree create" withClaude.programs.claude-code.rules.herdr
            && withOpencode.programs.opencode.context == withClaude.programs.claude-code.rules.herdr;
          message = "Herdr must give Claude Code and OpenCode the same worktree rule.";
        }
        {
          assertion =
            withClaude.programs.claude-code.settings.hooks.PreToolUse == [
              {
                matcher = "Bash";
                hooks = [
                  {
                    type = "command";
                    command = "bash '${hooksDir}/herdr-worktree-guard.sh'";
                    timeout = 10;
                  }
                ];
              }
            ];
          message = "The Claude PreToolUse hook must call the managed worktree guard for Bash.";
        }
        {
          assertion =
            (lib.head withClaude.programs.claude-code.settings.hooks.SessionStart).hooks == [
              {
                type = "command";
                command = "bash '${hookPath}' session";
                timeout = 10;
              }
            ];
          message = "The Claude SessionStart hook must call the managed Herdr hook.";
        }
      ];

      # Herdr's own parsers accept the generated config and the managed hook,
      # and the installed guard denies only `git worktree add` inside Herdr.
      checks.herdr-integration = pkgs.runCommand "herdr-integration" { } ''
        export HOME=$TMPDIR/home
        mkdir -p $HOME
        HERDR_CONFIG_PATH=${settings} ${lib.getExe alone.programs.herdr.package} config check
        ${shadowed declaredKeys} > shadowed
        if [ -s shadowed ]; then cat shadowed >&2; exit 1; fi
        echo '{"last_pane": "prefix+c"}' > taken.json
        ${shadowed "taken.json"} | grep 'disables the default new_tab'
        cp -rL ${withClaude.home-files}/.claude $HOME/.claude
        ${lib.getExe alone.programs.herdr.package} integration status | grep '^claude: current '

        guard() {
          printf '{"tool_input":{"command":"%s"}}' "$2" |
            HERDR_ENV=$1 bash $HOME/.claude/hooks/herdr-worktree-guard.sh
        }
        guard 1 'git worktree add ../x -b x' |
          ${lib.getExe pkgs.jq} -e '.hookSpecificOutput.permissionDecision == "deny"'
        guard 1 'git -C /repo worktree add /tmp/x' |
          ${lib.getExe pkgs.jq} -e '.hookSpecificOutput.permissionDecision == "deny"'
        [ -z "$(guard 1 'git worktree list')" ]
        [ -z "$(guard 1 'herdr worktree create --branch x --no-focus')" ]
        [ -z "$(guard "" 'git worktree add ../x -b x')" ]
        touch $out
      '';
    };
}
