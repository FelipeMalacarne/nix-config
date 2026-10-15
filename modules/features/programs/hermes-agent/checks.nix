{ inputs, self, ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    let
      inherit (import ../../../checks/config/fixtures.nix { inherit inputs self; })
        mkFeatureConfig
        homeOf
        baseOnly
        desktopWithoutHermes
        ;
      hermes = mkFeatureConfig [
        self.modules.nixos.base
        self.modules.nixos.hermes-agent
      ];
      home = homeOf hermes;
      settings = home.services.hermes-agent.settings;
      zaros = self.nixosConfigurations.zaros.config;
      zarosHome = homeOf zaros;
      mkHermesHome =
        services:
        (inputs.home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            self.modules.homeManager.hermes-agent
            {
              home = {
                username = "hermes-check";
                homeDirectory = "/home/hermes-check";
                stateVersion = "24.11";
              };
              services.hermes-agent = services;
            }
          ];
        }).config;
      externalToken = mkHermesHome { backend.sessionTokenFile = "/run/hermes-check/token"; };
      withoutBackend = mkHermesHome { backend.mode = "none"; };
      withoutService = mkHermesHome { enable = lib.mkForce false; };
      desktop = lib.findFirst (package: lib.getName package == "hermes-desktop") null home.home.packages;
      inactive =
        host:
        let
          h = homeOf host;
        in
        !(h.programs.hermes-agent.enable or false)
        && !(h.programs.hermes-agent.desktop.enable or false)
        && !(h.services.hermes-agent.enable or false)
        && lib.all (package: !(builtins.elem package h.home.packages)) [
          home.programs.hermes-agent.package
          desktop
        ]
        && !(h.home.sessionVariables ? HERMES_HOME)
        && lib.all (name: !(builtins.hasAttr name h.home.activation)) [
          "hermesAgentSetup"
          "hermesAgentWorkflow"
          "hermesAgentSessionToken"
        ]
        && !(h.systemd.user.services ? hermes-backend)
        && !(h.systemd.user.services ? hermes-agent);
      omitted = [
        baseOnly
        desktopWithoutHermes
        self.nixosConfigurations.saradomin.config
        self.nixosConfigurations.saradomin-vm.config
      ];
      agentCheck =
        assert lib.assertMsg (
          inputs.hermes-agent.inputs.nixpkgs.rev
          == (builtins.fromJSON (builtins.readFile "${inputs.hermes-agent}/flake.lock"))
          .nodes.nixpkgs.locked.rev
        ) "Hermes must retain upstream's nixpkgs pin for the Electron header checksum";
        assert lib.assertMsg (
          home.programs.hermes-agent.enable
          && home.programs.hermes-agent.desktop.enable
          && home.services.hermes-agent.enable
        ) "Importing Hermes must enable CLI, desktop and Home Manager state";
        assert lib.assertMsg (
          lib.all (path: lib.attrByPath path false settings) [
            [
              "memory"
              "memory_enabled"
            ]
            [
              "memory"
              "user_profile_enabled"
            ]
            [
              "skills"
              "write_approval"
            ]
            [
              "security"
              "redact_secrets"
            ]
            [
              "agent"
              "verify_on_stop"
            ]
            [
              "checkpoints"
              "enabled"
            ]
          ]
          && (settings.approvals.mode or "") == "smart"
          && builtins.elem "KUBECONFIG" (settings.terminal.env_passthrough or [ ])
        ) "Hermes must enable reviewed learning, infrastructure safeguards and Kubernetes passthrough";
        assert lib.assertMsg (
          home.home.activation ? hermesAgentWorkflow
          && builtins.elem "hermesAgentSetup" home.home.activation.hermesAgentWorkflow.after
          && home.services.hermes-agent.hermesHomeFiles == { }
        ) "Hermes must seed a writable workflow after state setup without replacing learned files";
        assert lib.assertMsg (lib.all
          (
            package:
            builtins.elem package home.services.hermes-agent.extraPackages
            && lib.hasInfix (builtins.unsafeDiscardStringContext "${package}/bin") (
              lib.concatStringsSep "\n" home.systemd.user.services.hermes-backend.Service.Environment
            )
          )
          (
            with pkgs;
            [
              nix
              nixfmt
              gnumake
              git
              jq
              ripgrep
              fd
              uv
              curl
              systemd
            ]
          )
        ) "Hermes backend must receive Nix workflow tools without relying on an interactive shell";
        assert lib.assertMsg (
          home.services.hermes-agent.backend.mode == "dashboard"
          && home.services.hermes-agent.backend.host == "127.0.0.1"
          && home.home.sessionVariables.HERMES_HOME == "${home.home.homeDirectory}/.hermes"
          && home.systemd.user.services ? hermes-backend
        ) "Hermes must use its personal state directory and a loopback user dashboard";
        assert lib.assertMsg (
          home.services.hermes-agent.backend.sessionTokenFile
          == "${home.services.hermes-agent.hermesHome}/.backend-session-token"
          && home.home.activation ? hermesAgentSessionToken
          && builtins.elem "hermesAgentSetup" home.home.activation.hermesAgentSessionToken.after
          && builtins.elem "reloadSystemd" home.home.activation.hermesAgentSessionToken.before
        ) "Desktop and backend must share a token initialized after state setup";
        assert lib.assertMsg (
          !(externalToken.home.activation ? hermesAgentSessionToken)
          && !(withoutBackend.home.activation ? hermesAgentSessionToken)
          && !(withoutService.home.activation ? hermesAgentSessionToken)
          && !(withoutService.home.activation ? hermesAgentWorkflow)
          && home.services.hermes-agent.environmentFiles == [ ]
          && home.services.hermes-agent.environment == { }
          && home.services.hermes-agent.authFile == null
        ) "Hermes must preserve caller-managed credentials and not initialize disabled state";
        # Concrete host selection is distinct from the reusable feature fixture.
        assert lib.assertMsg (
          zarosHome.programs.hermes-agent.enable
          && zarosHome.programs.hermes-agent.desktop.enable
          && zarosHome.services.hermes-agent.enable
          && !(zaros.systemd.services ? hermes-agent)
          && !(zaros.systemd.services ? hermes-backend)
          && zaros.users.users.${zaros.my.user.name}.linger
        ) "Zaros must select a lingering user Hermes instance, never a system instance";
        assert lib.assertMsg (lib.all inactive omitted)
          "Omitting Hermes must install no applications, start no services, and manage no state";
        pkgs.runCommand "hermes-agent-integration" { } "touch $out";
      mkWeb =
        web:
        mkFeatureConfig [
          self.modules.nixos.base
          self.modules.nixos.hermes-agent
          self.modules.nixos.tailscale
          {
            my.ai.hermes.web = {
              enable = true;
              publicUrl = "https://hermes-check.example.ts.net";
              environmentFile = "/run/hermes-check/environment";
            }
            // web;
          }
        ];
      web = mkWeb { };
      otherPort = mkWeb { publicUrl = "https://hermes-check.example.ts.net:8443"; };
      disabled = mkWeb { enable = false; };
      webAbsent =
        host:
        !(host.systemd.services ? hermes-tailnet)
        && !((homeOf host).systemd.user.services ? hermes-web)
        && !((lib.attrByPath [ "sops" "secrets" ] { } host) ? hermes-web);
      invalidWeb =
        extra:
        let
          candidate = mkWeb extra;
          result = builtins.tryEval (
            let
              assertions = map (a: a.assertion) (candidate.assertions ++ (homeOf candidate).assertions);
            in
            builtins.deepSeq candidate.my.ai.hermes.web.port (
              builtins.deepSeq assertions (lib.all lib.id assertions)
            )
          );
        in
        !result.success || !result.value;
      webCheck =
        assert lib.assertMsg (
          zaros.my.ai.hermes.web.enable
          && zarosHome.systemd.user.services ? hermes-web
          && builtins.elem "HERMES_DASHBOARD_PUBLIC_URL=https://zaros.osiris-fish.ts.net" zarosHome.systemd.user.services.hermes-web.Service.Environment
          &&
            zarosHome.systemd.user.services.hermes-web.Service.EnvironmentFile
            == [ zaros.sops.secrets.hermes-web.path ]
          && zarosHome.services.hermes-agent.environmentFiles == [ ]
          && zarosHome.services.hermes-agent.environment == { }
          && !((zarosHome.services.hermes-agent.settings.dashboard or { }) ? public_url)
          && zaros.systemd.services ? hermes-tailnet
        ) "Zaros must select a separate authenticated web listener with web-only URL and credentials";
        assert lib.assertMsg (
          lib.hasInfix "serve --yes --https=443 http://127.0.0.1:9120" web.systemd.services.hermes-tailnet.serviceConfig.ExecStart
          && !(lib.hasInfix "--bg" web.systemd.services.hermes-tailnet.serviceConfig.ExecStart)
          && web.systemd.services.hermes-tailnet.serviceConfig.Restart == "always"
          && web.systemd.services.hermes-tailnet.serviceConfig.KillSignal == "SIGINT"
          && builtins.elem "tailscaled.service" web.systemd.services.hermes-tailnet.partOf
          && lib.hasInfix ".auth_required == true" web.systemd.services.hermes-tailnet.preStart
        ) "The proxy must own and recover a foreground route and wait for authenticated Hermes";
        assert lib.assertMsg (
          lib.hasInfix "serve --yes --https=8443 http://127.0.0.1:9120" otherPort.systemd.services.hermes-tailnet.serviceConfig.ExecStart
          && lib.hasInfix "hermes-check.example.ts.net." otherPort.systemd.services.hermes-tailnet.preStart
          && lib.all (a: a.assertion) otherPort.assertions
        ) "publicUrl must configure HTTPS independently of the loopback backend port";
        assert lib.assertMsg (lib.all webAbsent (
          [ disabled ] ++ omitted
        )) "Disabling web access or omitting Hermes must remove both web units and its secret";
        assert lib.assertMsg (
          web.networking.firewall.allowedTCPPorts == disabled.networking.firewall.allowedTCPPorts
          && web.networking.firewall.trustedInterfaces == disabled.networking.firewall.trustedInterfaces
        ) "Hermes web must not widen firewall access or change Tailscale trust";
        assert lib.assertMsg (lib.all invalidWeb [
          { publicUrl = "http://hermes-check.example.ts.net"; }
          { publicUrl = "https://hermes-check.example.ts.net/path"; }
          { publicUrl = "https://hermes-check.example.ts.net:0"; }
          { publicUrl = "https://hermes-check.example.ts.net:65536"; }
          { environmentFile = null; }
          { environmentFile = "/nix/store/unsafe-secret"; }
          { port = 0; }
          { port = home.services.hermes-agent.backend.port; }
        ]) "Unsafe origins, credential paths and colliding listener ports must fail evaluation";
        assert lib.assertMsg (
          (zarosHome.systemd.user.services.hermes-web.Unit."X-Restart-Triggers" or [ ]) != [ ]
          && zaros.sops.secrets.hermes-web.owner == zaros.my.user.name
          && zaros.sops.secrets.hermes-web.mode == "0400"
        ) "Credential updates must restart the web listener, with private user-owned delivery";
        pkgs.runCommand "hermes-web-integration" { } "touch $out";
      manifest =
        host:
        let
          h = homeOf host;
        in
        pkgs.writeText "hermes-web-runtime.json" (
          builtins.toJSON {
            private = h.systemd.user.services.hermes-backend.Service;
            web = h.systemd.user.services.hermes-web.Service;
            tokenFile = h.services.hermes-agent.backend.sessionTokenFile;
            privatePort = h.services.hermes-agent.backend.port;
            stateDirectories =
              (import "${inputs.hermes-agent}/nix/moduleCommon.nix" { inherit lib; }).stateSubdirs;
            publicUrl = host.my.ai.hermes.web.publicUrl;
            preStart = host.systemd.services.hermes-tailnet.preStart;
            tailscale = lib.getExe host.services.tailscale.package;
            curl = lib.getExe pkgs.curl;
            bash = lib.getExe pkgs.bash;
          }
        );
      webRuntimeCheck = pkgs.runCommand "hermes-web-runtime" { } (
        lib.concatMapStringsSep "\n"
          (host: ''
            ${pkgs.python3.withPackages (ps: [ ps.websockets ])}/bin/python3 \
              ${./config/test_web_runtime.py} ${manifest host}
            ${pkgs.python3}/bin/python3 ${./config/test_web_preflight.py} ${manifest host}
          '')
          [
            web
            otherPort
          ]
        + "\ntouch $out\n"
      );
      backendLauncher = builtins.head home.systemd.user.services.hermes-backend.Service.ExecStart;
      runtimeCheck = pkgs.runCommand "hermes-runtime-state" { } ''
        ${pkgs.python3}/bin/python3 ${./config}/test_runtime_state.py -v
        # Inspect upstream-generated launchers, not copies of their source.
        grep -Fq 'HERMES_DASHBOARD_SESSION_TOKEN' ${backendLauncher}
        grep -Fq '${home.services.hermes-agent.backend.sessionTokenFile}' ${backendLauncher}
        grep -Fq '${home.programs.hermes-agent.package}/bin/hermes' ${backendLauncher}
        grep -Fq 'HERMES_DESKTOP_REMOTE_TOKEN' ${desktop}/bin/hermes-desktop
        grep -Fq 'http://127.0.0.1:9119' ${desktop}/bin/hermes-desktop
        grep -Fq '${home.services.hermes-agent.backend.sessionTokenFile}' ${desktop}/bin/hermes-desktop
        touch $out
      '';
    in
    {
      checks = lib.optionalAttrs (system == "x86_64-linux") {
        hermes-agent = agentCheck;
        hermes-runtime-state = runtimeCheck;
        hermes-web = webCheck;
        hermes-web-runtime = webRuntimeCheck;
      };
    };
}
