{ config, ... }:
let
  registry = config.flake.modules;
in
{
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
        description = "Existing, interactively trusted working directory for the Claude Remote Control server.";
      };

      config.systemd.user.services.claude-remote-control = {
        Unit = {
          Description = "Claude Code Remote Control";
          After = [ "network-online.target" ];
          StartLimitIntervalSec = 300;
          StartLimitBurst = 3;
        };
        Service = {
          # HM's plugin wrapper injects global --plugin-dir flags, which the
          # Remote Control server cannot forward to its child sessions.
          ExecStart = "${lib.getExe pkgs.claude-code} remote-control --name zaros --no-create-session-in-dir";
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
