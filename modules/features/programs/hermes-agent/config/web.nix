{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.hermes-agent.web;
  user = config.my.user.name;
  enabled = config.my.hermes-agent.enable && cfg.enable;
  origin = builtins.match "https://([a-z0-9-]+\\.[a-z0-9-]+\\.ts\\.net)(:([1-9][0-9]*))?" cfg.publicUrl;
  hostname = if origin == null then "" else builtins.elemAt origin 0;
  httpsPort =
    if origin == null || builtins.elemAt origin 2 == null then
      443
    else
      lib.toInt (builtins.elemAt origin 2);
in
{
  options.my.hermes-agent.web = {
    enable = lib.mkEnableOption "private Hermes web access through Tailscale";
    publicUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "https://workstation.example.ts.net:8443";
      description = "Exact Tailscale HTTPS origin, optionally with a port (default 443). No path or trailing slash.";
    };
    port = lib.mkOption {
      type = lib.types.ints.between 1 65535;
      default = 9120;
      description = "Loopback port for the authenticated web listener, separate from Desktop.";
    };
    restartTriggers = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = "Non-secret or encrypted inputs whose changes restart the web listener on rebuild.";
    };
    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Private runtime environment file containing
        HERMES_DASHBOARD_BASIC_AUTH_PASSWORD_HASH and
        HERMES_DASHBOARD_BASIC_AUTH_SECRET. Use a SOPS secret's path,
        never a Nix path literal. The login username is my.user.name.
        This file is read by systemd, not merged into the existing Hermes .env.
      '';
    };
  };

  config = lib.mkIf enabled {
    assertions = [
      {
        assertion = config.services.tailscale.enable;
        message = "Hermes web access requires Tailscale to be enabled.";
      }
      {
        assertion = origin != null && httpsPort <= 65535;
        message = "Hermes web publicUrl must be https://machine.tailnet.ts.net with an optional valid HTTPS port.";
      }
      {
        assertion =
          cfg.environmentFile != null
          && lib.hasPrefix "/" cfg.environmentFile
          && !(lib.hasPrefix "/nix/store/" cfg.environmentFile);
        message = "Hermes web requires a private absolute runtime environmentFile outside the Nix store.";
      }
    ];

    # System and user managers cannot order units against each other. Probe
    # readiness instead, and never publish a listener that has no auth gate.
    systemd.services.hermes-tailnet = {
      description = "Private Tailscale HTTPS entrance for Hermes";
      wantedBy = [
        "multi-user.target"
        "tailscaled.service"
      ];
      wants = [ "tailscaled.service" ];
      after = [
        "tailscaled.service"
        "tailscaled-autoconnect.service"
        "tailscaled-set.service"
      ];
      partOf = [ "tailscaled.service" ];
      unitConfig.StartLimitIntervalSec = 0;
      preStart = ''
        set -euo pipefail
        ${lib.getExe config.services.tailscale.package} status --json |
          ${lib.getExe pkgs.jq} -e --arg dns ${lib.escapeShellArg "${hostname}."} \
            '.BackendState == "Running" and .Self.DNSName == $dns' >/dev/null
        # Do not replace another application's persistent or foreground route.
        ${lib.getExe config.services.tailscale.package} serve status --json |
          ${lib.getExe pkgs.jq} -e \
            --arg port ${lib.escapeShellArg (toString httpsPort)} \
            --arg target ${lib.escapeShellArg "${hostname}:${toString httpsPort}"} \
            '[., ((.Foreground // {})[])] | all(.TCP[$port] == null and .AllowFunnel[$target] != true)' >/dev/null
        ${lib.getExe pkgs.curl} --fail --silent --show-error --max-time 10 \
          --header ${lib.escapeShellArg "Host: ${lib.removePrefix "https://" cfg.publicUrl}"} \
          http://127.0.0.1:${toString cfg.port}/api/status |
          ${lib.getExe pkgs.jq} -e \
            '.auth_required == true and (.auth_providers | index("basic") != null)' >/dev/null
      '';
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe config.services.tailscale.package} serve --yes --https=${toString httpsPort} http://127.0.0.1:${toString cfg.port}";
        # Foreground Serve can exit successfully when its IPN bus watcher is
        # closed; recover the route even though that EOF is not an error.
        Restart = "always";
        RestartSec = "5s";
        # No --bg: Serve removes its foreground route when interrupted. Do not
        # reset the daemon's other routes, either at startup or shutdown.
        KillSignal = "SIGINT";
        TimeoutStopSec = "20s";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    };

    home-manager.users.${user} =
      { config, ... }:
      let
        hermes = config.services.hermes-agent;
        profileName =
          if builtins.baseNameOf (builtins.dirOf hermes.hermesHome) == "profiles" then
            builtins.baseNameOf hermes.hermesHome
          else
            "default";
        privateService = lib.attrByPath [
          "systemd"
          "user"
          "services"
          "hermes-backend"
          "Service"
        ] { } config;
      in
      {
        # Keep both daemons on their configured home, not the CLI's sticky
        # active_profile. Profile flags are handled before Hermes imports.
        services.hermes-agent.backend.extraArgs = lib.mkBefore [
          "--profile"
          profileName
        ];
        systemd.user.services.hermes-backend.Service.Environment = [
          "HERMES_DASHBOARD_PUBLIC_URL=http://127.0.0.1:${toString hermes.backend.port}"
        ];
        assertions = [
          {
            assertion =
              hermes.enable
              && hermes.backend.mode != "none"
              && hermes.backend.host == "127.0.0.1"
              && hermes.backend.port != cfg.port;
            message = "Hermes web requires a separate, enabled loopback Desktop backend.";
          }
        ];
        systemd.user.services.hermes-web = {
          Unit = {
            Description = "Hermes authenticated web dashboard";
            After = [ "default.target" ];
            X-Restart-Triggers = map (file: "${file}") cfg.restartTriggers;
          };
          Install.WantedBy = [ "default.target" ];
          # Reuse upstream's effective PATH, working directory and hardening,
          # but never its private Desktop token or launcher.
          Service = privateService // {
            ExecStart = [
              (lib.escapeShellArgs [
                "${config.programs.hermes-agent.package}/bin/hermes"
                "--profile"
                profileName
                "dashboard"
                "--host"
                "127.0.0.1"
                "--port"
                (toString cfg.port)
                "--no-open"
                "--isolated"
              ])
            ];
            Environment = (privateService.Environment or [ ]) ++ [
              "HERMES_DASHBOARD_PUBLIC_URL=${cfg.publicUrl}"
              "HERMES_DASHBOARD_BASIC_AUTH_USERNAME=${user}"
            ];
            EnvironmentFile = lib.optional (cfg.environmentFile != null) cfg.environmentFile;
            UnsetEnvironment = [
              "HERMES_DESKTOP"
              "HERMES_DASHBOARD_SESSION_TOKEN"
              "HERMES_DESKTOP_REMOTE_URL"
              "HERMES_DESKTOP_REMOTE_TOKEN"
            ];
          };
        };
      };
  };
}
