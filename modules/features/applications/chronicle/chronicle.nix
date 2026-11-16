{
  config,
  inputs,
  secretsDir,
  ...
}:
let
  registry = config.flake.modules;
  package = pkgs: inputs.chronicle.packages.${pkgs.stdenv.hostPlatform.system}.chronicle;

  # Values written verbatim into systemd Environment= lines: no whitespace,
  # quotes, backslashes or `%` specifiers.
  envValue = "[^[:space:]%\"'\\\\]+";

  # Settings the NixOS companion declares for the host and forwards to Home
  # Manager; `home` is the user's home directory on either side.
  agentOptions =
    { lib, home }:
    {
      serverUrl = lib.mkOption {
        type = lib.types.strMatching "https://[A-Za-z0-9.-]+(:[0-9]+)?";
        default = "https://chronicle.saradomin.ftm.dev.br";
        description = "Planner server the agent links to (CHRONICLE_URL); no path or trailing slash.";
      };
      clientId = lib.mkOption {
        type = lib.types.strMatching envValue;
        example = "chronicle-agent";
        description = "Client id of the Zitadel machine user with the `microbot:agent` role (MICROBOT_AGENT_CLIENT_ID).";
      };
      account = lib.mkOption {
        type = lib.types.nullOr (lib.types.strMatching envValue);
        default = null;
        example = "acc_myrsn";
        description = "Chronicle account the agent declares (MICROBOT_AGENT_ACCOUNT); null declares none.";
      };
      harnessDir = lib.mkOption {
        type = lib.types.strMatching "/${envValue}";
        default = "${home}/repos/chronicle";
        description = ''
          Writable chronicle checkout whose `microbot/` harness starts the dev
          client (MICROBOT_HARNESS_DIR). The agent runs `nix develop
          <harnessDir>#microbot --command <harnessDir>/microbot/bin/mb-client`.
        '';
      };
    };

  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.chronicle.agent;
      private = path: !(lib.hasPrefix "${builtins.storeDir}/" path);
    in
    {
      imports = [ registry.homeManager.chronicle ];

      options.my.chronicle.agent =
        agentOptions {
          inherit lib;
          home = config.home.homeDirectory;
        }
        // {
          clientSecretFile = lib.mkOption {
            type = lib.types.strMatching "/${envValue}";
            description = ''
              Private runtime file holding the machine user's client secret
              (MICROBOT_AGENT_CLIENT_SECRET_FILE). Only its path enters the
              unit; never a Nix store path.
            '';
          };
        };

      config = {
        assertions = [
          {
            assertion = private cfg.clientSecretFile;
            message = "chronicle-agent clientSecretFile must be a private runtime file, never a Nix store path.";
          }
          {
            assertion = private cfg.harnessDir;
            message = "chronicle-agent harnessDir must be a writable checkout: mb-client builds plugins in it.";
          }
        ];

        # `chronicle agent` (docs/08 of the chronicle repository): an outbound
        # link to the planner that runs only its closed command list against
        # the harness's dev client, which it always starts headless on Xvfb :99
        # with x11vnc on loopback. It needs no graphical session.
        systemd.user.services.chronicle-agent = {
          Unit = {
            Description = "Chronicle Microbot control agent";
            Documentation = [
              "https://github.com/FelipeMalacarne/chronicle/blob/main/docs/08-controle-microbot.md"
            ];
            # The agent reconnects to the server by itself and exits only on a
            # startup error, such as a secret not decrypted yet: keep retrying.
            StartLimitIntervalSec = 0;
          };
          Service = {
            ExecStart = "${lib.getExe (package pkgs)} agent";
            # Same working directory as `just agent`.
            WorkingDirectory = cfg.harnessDir;
            Environment = [
              "CHRONICLE_URL=${cfg.serverUrl}"
              "MICROBOT_AGENT_CLIENT_ID=${cfg.clientId}"
              "MICROBOT_AGENT_CLIENT_SECRET_FILE=${cfg.clientSecretFile}"
              "MICROBOT_HARNESS_DIR=${cfg.harnessDir}"
              # What the harness needs beyond its dev shell: nix and git to
              # enter the checkout's flake, setsid to detach the client, and
              # PipeWire's tools to mute the headless client.
              "PATH=${
                lib.makeBinPath (
                  with pkgs;
                  [
                    nix
                    git
                    bash
                    coreutils
                    util-linux
                    pipewire
                    wireplumber
                  ]
                )
              }"
            ]
            ++ lib.optional (cfg.account != null) "MICROBOT_AGENT_ACCOUNT=${cfg.account}";
            Restart = "on-failure";
            RestartSec = "5s";
            RestartSteps = 6;
            RestartMaxDelaySec = "5min";
            # mb-client detaches the game (setsid) so it outlives whoever
            # started it. Stopping or restarting the agent, including on a
            # Home Manager switch, must not close the game: stop the client
            # from the planner or with `mb-client stop`.
            KillMode = "process";
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
    };

  systemModule =
    { config, lib, ... }:
    let
      user = config.my.user.name;
      cfg = config.my.chronicle.agent;
    in
    {
      imports = [ registry.nixos.sops ];

      options.my.chronicle.agent =
        agentOptions {
          inherit lib;
          home = config.users.users.${user}.home;
        }
        // {
          secret = {
            sopsFile = lib.mkOption {
              type = lib.types.path;
              default = secretsDir + "/chronicle-agent.yaml";
              description = "SOPS file holding the machine user's client secret.";
            };
            key = lib.mkOption {
              type = lib.types.str;
              default = "client-secret";
              description = "Key of the client secret in the SOPS file.";
            };
          };
        };

      config = {
        sops.secrets.chronicle-agent-client-secret = {
          inherit (cfg.secret) sopsFile key;
          owner = user;
          mode = "0400";
        };
        # The agent serves the planner without a login session.
        users.users.${user}.linger = true;

        home-manager.sharedModules = [ registry.homeManager.chronicle-agent ];
        home-manager.users.${user} = {
          my.chronicle.agent = builtins.removeAttrs cfg [ "secret" ] // {
            clientSecretFile = config.sops.secrets.chronicle-agent-client-secret.path;
          };
          # The agent reads its secret once, at start.
          systemd.user.services.chronicle-agent.Unit.X-Restart-Triggers = [ "${cfg.secret.sopsFile}" ];
        };
      };
    };
in
{
  # Chronicle's CLI, MCP server and Microbot agent (github:FelipeMalacarne/chronicle):
  # `chronicle login`, `accounts connect`, `workers`, `mcp` and `agent`. Packaging and
  # its vendorHash live in that flake; the server itself runs on saradomin.
  flake.modules.homeManager.chronicle =
    { pkgs, ... }:
    {
      home.packages = [ (package pkgs) ];
    };

  # `chronicle agent` as a lingering user service on the game machine, its
  # Zitadel machine user's secret decrypted by sops-nix. Linux only: the
  # harness runs the game on Xvfb.
  flake.modules.homeManager.chronicle-agent = homeModule;
  flake.modules.nixos.chronicle-agent = systemModule;
}
