{
  inputs,
  self,
  secretsDir,
  ...
}:
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      fixtures,
      evalHome,
      mkAssertCheck,
      ...
    }:
    let
      registry = self.modules;
      chronicle = inputs.chronicle.packages.${system}.chronicle;
      names = cfg: map (p: p.pname or (builtins.parseDrvName p.name).name) cfg.home.packages;
      hasAgent = cfg: cfg.systemd.user.services ? chronicle-agent;

      # Synthetic settings: no real secret, machine user or checkout.
      settings = {
        clientId = "agent-check";
        clientSecretFile = "/run/agent-check/client-secret";
      };
      agentHome =
        agent:
        evalHome [
          registry.homeManager.chronicle-agent
          { my.chronicle.agent = agent; }
        ];
      home = agentHome settings;
      custom = agentHome (
        settings
        // {
          serverUrl = "https://chronicle.example.test:8443";
          account = "acc_check";
          harnessDir = "/srv/chronicle-check";
        }
      );
      service = cfg: cfg.systemd.user.services.chronicle-agent;
      env = cfg: (service cfg).Service.Environment;
      hasEnv = cfg: line: builtins.elem line (env cfg);
      envNames = cfg: map (line: builtins.head (lib.splitString "=" line)) (env cfg);
      searchPath = cfg: lib.removePrefix "PATH=" (lib.findFirst (lib.hasPrefix "PATH=") "" (env cfg));
      holds = cfg: lib.all (a: a.assertion) cfg.assertions;
      rejected =
        agent:
        let
          cfg = agentHome agent;
          result = builtins.tryEval (builtins.deepSeq (env cfg) (holds cfg));
        in
        !result.success || !result.value;

      # The NixOS companion: SOPS delivery, forwarding and lingering.
      sopsFile = pkgs.writeText "chronicle-agent-check.yaml" "client-secret: ENC[synthetic]\n";
      mkHost =
        agent:
        fixtures.mkFeatureConfig [
          registry.nixos.base
          registry.nixos.chronicle-agent
          {
            my.chronicle.agent = {
              clientId = "agent-check";
            }
            // agent;
          }
        ];
      host = mkHost {
        account = "acc_check";
        secret.sopsFile = "${sopsFile}";
      };
      defaults = mkHost { };
      hostHome = fixtures.homeOf host;
      user = host.my.user.name;
      secret = host.sops.secrets.chronicle-agent-client-secret;
    in
    {
      checks = {
        chronicle = mkAssertCheck "chronicle-composition" [
          {
            assertion = !(builtins.elem "chronicle" (names (evalHome [ ])));
            message = "Chronicle must not be installed without importing its aspect.";
          }
          {
            assertion = builtins.elem "chronicle" (names (evalHome [ registry.homeManager.chronicle ]));
            message = "Importing the chronicle aspect must install its CLI.";
          }
        ];
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        # The host's rendered unit must load in a user manager without
        # warnings: systemd only logs unknown or invalid directives and ignores
        # them. It also fails on a missing ExecStart binary.
        chronicle-agent-unit =
          pkgs.runCommand "chronicle-agent-unit" { nativeBuildInputs = [ pkgs.systemd ]; }
            ''
              mkdir -p "$TMPDIR/runtime"
              export XDG_RUNTIME_DIR="$TMPDIR/runtime" SYSTEMD_LOG_TARGET=console SYSTEMD_LOG_COLOR=0
              export SYSTEMD_UNIT_PATH=${pkgs.systemd}/example/systemd/user
              cp ${hostHome.xdg.configFile."systemd/user/chronicle-agent.service".source} \
                "$TMPDIR/chronicle-agent.service"
              systemd-analyze --user verify --man=no "$TMPDIR/chronicle-agent.service" >"$TMPDIR/verify.log" 2>&1 \
                || { cat "$TMPDIR/verify.log"; exit 1; }
              if [ -s "$TMPDIR/verify.log" ]; then
                cat "$TMPDIR/verify.log"
                exit 1
              fi
              touch "$out"
            '';
        chronicle-agent = mkAssertCheck "chronicle-agent" [
          {
            assertion =
              !hasAgent (evalHome [ ])
              && !hasAgent (evalHome [ registry.homeManager.chronicle ])
              && !hasAgent (fixtures.homeOf fixtures.baseOnly)
              && !(fixtures.baseOnly ? sops);
            message = "The agent and its secret must not exist without importing the chronicle-agent aspect.";
          }
          {
            assertion = builtins.elem "chronicle" (names home) && holds home;
            message = "The agent aspect must install the CLI and evaluate without failed assertions.";
          }
          {
            assertion =
              lib.toList (service home).Service.ExecStart == [ "${lib.getExe chronicle} agent" ]
              && (service home).Service.WorkingDirectory == "/tmp/feature-check/repos/chronicle"
              && (service home).Install.WantedBy == [ "default.target" ];
            message = "The agent must run `chronicle agent` from the harness checkout under default.target.";
          }
          {
            assertion =
              hasEnv home "CHRONICLE_URL=https://chronicle.saradomin.ftm.dev.br"
              && hasEnv home "MICROBOT_AGENT_CLIENT_ID=agent-check"
              && hasEnv home "MICROBOT_AGENT_CLIENT_SECRET_FILE=/run/agent-check/client-secret"
              && hasEnv home "MICROBOT_HARNESS_DIR=/tmp/feature-check/repos/chronicle"
              && !(builtins.elem "MICROBOT_AGENT_ACCOUNT" (envNames home))
              && !(builtins.elem "MICROBOT_AGENT_CLIENT_SECRET" (envNames home));
            message = "The agent must default to saradomin, declare no account and get its secret only as a file path.";
          }
          {
            assertion =
              hasEnv custom "CHRONICLE_URL=https://chronicle.example.test:8443"
              && hasEnv custom "MICROBOT_AGENT_ACCOUNT=acc_check"
              && hasEnv custom "MICROBOT_HARNESS_DIR=/srv/chronicle-check"
              && (service custom).Service.WorkingDirectory == "/srv/chronicle-check";
            message = "Server URL, declared account and harness checkout must reach the agent's environment.";
          }
          {
            assertion =
              lib.all
                (package: lib.hasInfix (builtins.unsafeDiscardStringContext "${package}/bin") (searchPath home))
                (
                  with pkgs;
                  [
                    nix
                    git
                    util-linux
                  ]
                );
            message = "The agent's PATH must reach nix develop, the checkout's Git and setsid for mb-client.";
          }
          {
            assertion =
              (service home).Service.Restart == "on-failure"
              && (service home).Service.RestartSteps > 0
              && (service home).Service ? RestartMaxDelaySec
              && (service home).Unit.StartLimitIntervalSec == 0
              && (service home).Service.KillMode == "process";
            message = "The agent must restart on failure with backoff and never take the detached game client down with it.";
          }
          {
            assertion = lib.all rejected [
              (builtins.removeAttrs settings [ "clientId" ])
              (builtins.removeAttrs settings [ "clientSecretFile" ])
              (settings // { clientSecretFile = "${builtins.storeDir}/unsafe-secret"; })
              (settings // { clientSecretFile = "run/agent-check/client-secret"; })
              (settings // { harnessDir = "${builtins.storeDir}/chronicle-source"; })
              (settings // { harnessDir = "repos/chronicle"; })
              (settings // { harnessDir = "/srv/chronicle check"; })
              (settings // { serverUrl = "http://chronicle.example.test"; })
              (settings // { serverUrl = "https://chronicle.example.test/"; })
              (settings // { clientId = "agent check"; })
              (settings // { account = "acc_%n"; })
            ];
            message = "Missing settings, store or relative paths and unsafe environment values must fail evaluation.";
          }
          {
            assertion =
              secret.owner == user
              && secret.mode == "0400"
              && secret.key == "client-secret"
              && secret.sopsFile == "${sopsFile}"
              && host.sops.age.keyFile == "/var/lib/sops-age/keys.txt"
              && hasEnv hostHome "MICROBOT_AGENT_CLIENT_SECRET_FILE=${secret.path}"
              && lib.hasPrefix "/run/secrets/" secret.path;
            message = "The companion must decrypt the client secret with sops-nix, user-only, and pass the agent its path.";
          }
          {
            assertion =
              hasEnv hostHome "MICROBOT_AGENT_ACCOUNT=acc_check"
              && hasEnv hostHome "MICROBOT_AGENT_CLIENT_ID=agent-check"
              && hasEnv hostHome "MICROBOT_HARNESS_DIR=${host.users.users.${user}.home}/repos/chronicle"
              && (service hostHome).Unit.X-Restart-Triggers == [ "${sopsFile}" ]
              && host.users.users.${user}.linger
              && holds hostHome;
            message = "Host settings must reach the lingering user service, restarted when the encrypted secret changes.";
          }
          {
            assertion =
              toString defaults.my.chronicle.agent.secret.sopsFile
              == toString (secretsDir + "/chronicle-agent.yaml")
              && defaults.sops.secrets.chronicle-agent-client-secret.key == "client-secret";
            message = "The secret must default to secrets/chronicle-agent.yaml, key client-secret.";
          }
        ];
      };
    };
}
