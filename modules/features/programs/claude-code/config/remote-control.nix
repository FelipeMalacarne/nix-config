{ config, ... }:
let
  registry = config.flake.modules;
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks.claude-remote-control = pkgs.runCommand "claude-remote-control-state" { } ''
        export PYTHONDONTWRITEBYTECODE=1
        ${pkgs.python3}/bin/python3 ${./.}/test_prepare.py
        touch "$out"
      '';
    };

  flake.modules.nixos.claude-remote-control =
    { config, ... }:
    {
      users.users.${config.my.user.name}.linger = true;
      home-manager.users.${config.my.user.name}.imports = [ registry.homeManager.claude-remote-control ];
    };

  flake.modules.homeManager.claude-remote-control =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ registry.homeManager.claude-code ];

      options.my.ai.claude.remoteControl.directory = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/repos";
        description = "Existing working directory explicitly trusted for the Claude Remote Control server. Importing this feature also accepts Remote Control consent.";
      };

      config.systemd.user.services.claude-remote-control = {
        Unit = {
          Description = "Claude Code Remote Control";
          After = [ "network-online.target" ];
          StartLimitIntervalSec = 300;
          StartLimitBurst = 3;
        };
        Service = {
          ExecStartPre = lib.escapeShellArgs [
            "${pkgs.python3}/bin/python3"
            ./prepare.py
            (
              if config.programs.claude-code.configDir == "${config.home.homeDirectory}/.claude" then
                "${config.home.homeDirectory}/.claude.json"
              else
                "${config.programs.claude-code.configDir}/.claude.json"
            )
            config.my.ai.claude.remoteControl.directory
          ];
          Environment = lib.optional (
            config.programs.claude-code.configDir != "${config.home.homeDirectory}/.claude"
          ) "CLAUDE_CONFIG_DIR=${config.programs.claude-code.configDir}";
          # HM's plugin wrapper injects global --plugin-dir flags, which the
          # Remote Control server cannot forward to its child sessions.
          ExecStart = "${lib.getExe config.programs.claude-code.package} remote-control --name %H --no-create-session-in-dir";
          WorkingDirectory = config.my.ai.claude.remoteControl.directory;
          Restart = "always";
          RestartSec = 30;
          StandardInput = "null";
          UMask = "0077";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
