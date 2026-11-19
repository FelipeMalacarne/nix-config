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
        };
      };

      programs.opencode.skills.herdr = lib.mkIf config.programs.opencode.enable skill;

      # Mirrors `herdr integration install claude`: the same hook path and entry
      # keep `herdr integration status` current and a reinstall from duplicating it.
      programs.claude-code = lib.mkIf claude.enable {
        skills.herdr = skill;
        hooks."herdr-agent-state.sh" = claudeHook;
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
      absent = evalHome [ ];
      alone = evalHome [ registry.herdr ];
      withClaude = evalHome [
        registry.herdr
        claudeClient
      ];
      hookPath = "${withClaude.programs.claude-code.configDir}/hooks/herdr-agent-state.sh";
      settings = (pkgs.formats.toml { }).generate "herdr-config.toml" alone.programs.herdr.settings;
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

      # Herdr's own parsers accept the generated config and the managed hook.
      checks.herdr-integration = pkgs.runCommand "herdr-integration" { } ''
        export HOME=$TMPDIR/home
        mkdir -p $HOME
        HERDR_CONFIG_PATH=${settings} ${lib.getExe alone.programs.herdr.package} config check
        cp -rL ${withClaude.home-files}/.claude $HOME/.claude
        ${lib.getExe alone.programs.herdr.package} integration status | grep '^claude: current '
        touch $out
      '';
    };
}
