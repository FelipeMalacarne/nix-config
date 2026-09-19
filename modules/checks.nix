{ inputs, self, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    let
      linux = system == "x86_64-linux";
      darwin = system == "aarch64-darwin";
      zaros = self.nixosConfigurations.zaros.config;
      saradomin = self.nixosConfigurations.saradomin.config;
      zarosUser = zaros.my.user.name;
      zarosHome = zaros.home-manager.users.${zarosUser};
      sopsEnvironmentCheck =
        assert lib.assertMsg (
          (zarosHome.home.sessionVariables.SOPS_AGE_KEY_FILE or null) == "/var/lib/sops-age/keys.txt"
        ) "Interactive shells must discover the configured SOPS age identity";
        pkgs.runCommand "sops-environment" { } "touch $out";
      saradominLanDnsCheck =
        assert lib.assertMsg (
          lib.hasInfix "-s 10.10.0.0/22 -p udp --dport 53 -j nixos-fw-accept" saradomin.networking.firewall.extraCommands
          && lib.hasInfix "-s 10.10.0.0/22 -p tcp --dport 53 -j nixos-fw-accept" saradomin.networking.firewall.extraCommands
        ) "Saradomin DNS must be reachable from the home LAN over UDP and TCP only";
        pkgs.runCommand "saradomin-lan-dns" { } "touch $out";
      saradominAdGuardHomeCheck =
        let
          settings = saradomin.services.adguardhome.settings;
        in
        assert lib.assertMsg saradomin.services.adguardhome.enable
          "Saradomin must run AdGuard Home outside Kubernetes";
        assert lib.assertMsg (
          !saradomin.services.adguardhome.mutableSettings
        ) "Saradomin AdGuard Home configuration must remain declarative";
        assert lib.assertMsg (
          saradomin.services.adguardhome.settings.dns.bind_hosts == [
            "10.10.0.10"
            "100.106.58.87"
          ]
          && saradomin.services.adguardhome.settings.dns.port == 53
        ) "AdGuard Home must serve DNS on the Saradomin LAN and Tailscale addresses";
        assert lib.assertMsg (
          settings.dns.upstream_dns == [
            "https://cloudflare-dns.com/dns-query"
            "https://dns.quad9.net/dns-query"
          ]
          && settings.dns.dnssec_enabled
          && settings.filtering.protection_enabled
          && settings.filtering.filtering_enabled
          &&
            settings.filters == [
              {
                enabled = true;
                id = 1;
                name = "AdGuard DNS filter";
                url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
              }
            ]
        ) "AdGuard Home must use encrypted upstreams and enable DNS filtering";
        assert lib.assertMsg (
          settings.user_rules == [
            "||saradomin.ftm.dev.br^$client=10.10.0.0/22,dnstype=A,dnsrewrite=NOERROR;A;10.10.0.10"
            "||saradomin.ftm.dev.br^$client=100.64.0.0/10,dnstype=A,dnsrewrite=NOERROR;A;100.95.138.31"
            "||saradomin.ftm.dev.br^$dnstype=AAAA,dnsrewrite=NOERROR;;"
            "||saradomin^$client=10.10.0.0/22,dnstype=A,dnsrewrite=NOERROR;A;10.10.0.10"
            "||saradomin^$client=100.64.0.0/10,dnstype=A,dnsrewrite=NOERROR;A;100.95.138.31"
            "||saradomin^$dnstype=AAAA,dnsrewrite=NOERROR;;"
          ]
        ) "AdGuard Home must provide client-aware split DNS and empty AAAA responses";
        assert lib.assertMsg (
          saradomin.services.adguardhome.host == "127.0.0.1" && saradomin.services.adguardhome.port == 3000
        ) "The unauthenticated AdGuard Home UI must remain loopback-only";
        pkgs.runCommand "saradomin-adguard-home" { } "touch $out";
      hermesSettings = zarosHome.services.hermes-agent.settings;
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
              my.hermes-agent.enable = true;
              services.hermes-agent = services;
            }
          ];
        }).config;
      hermesExternalToken = mkHermesHome { backend.sessionTokenFile = "/run/hermes-check/token"; };
      hermesWithoutBackend = mkHermesHome { backend.mode = "none"; };
      hermesWithoutService = mkHermesHome { enable = lib.mkForce false; };
      zarosWithoutHermes =
        (inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit self inputs; };
          modules = [
            ../hosts/zaros
            { my.hermes-agent.enable = lib.mkForce false; }
          ];
        }).config;
      hermesInactive =
        host:
        let
          home = host.home-manager.users.${host.my.user.name};
        in
        !host.my.hermes-agent.enable
        && !home.programs.hermes-agent.enable
        && !home.programs.hermes-agent.desktop.enable
        && !home.services.hermes-agent.enable
        && !builtins.hasAttr "HERMES_HOME" home.home.sessionVariables
        && !builtins.hasAttr "hermesAgentSetup" home.home.activation
        && !builtins.hasAttr "hermesAgentWorkflow" home.home.activation
        && !builtins.hasAttr "hermesAgentSessionToken" home.home.activation
        && !builtins.hasAttr "hermes-backend" home.systemd.user.services
        && !builtins.hasAttr "hermes-agent" home.systemd.user.services;
      hermesAgentCheck =
        assert lib.assertMsg (
          inputs.hermes-agent.inputs.nixpkgs.rev
          == (builtins.fromJSON (builtins.readFile "${inputs.hermes-agent}/flake.lock"))
          .nodes.nixpkgs.locked.rev
        ) "Hermes must retain upstream's nixpkgs pin for the Electron header checksum";
        assert lib.assertMsg zarosHome.programs.hermes-agent.enable "Hermes CLI must be enabled on zaros";
        assert lib.assertMsg zarosHome.programs.hermes-agent.desktop.enable
          "Hermes desktop must be enabled on zaros";
        assert lib.assertMsg zarosHome.services.hermes-agent.enable
          "Hermes state must be managed by Home Manager";
        assert lib.assertMsg (
          lib.all (path: lib.attrByPath path false hermesSettings) [
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
          && (hermesSettings.approvals.mode or "") == "smart"
        ) "Hermes must explicitly enable learning, reviewed skill writes, and infrastructure safeguards";
        assert lib.assertMsg (
          builtins.hasAttr "hermesAgentWorkflow" zarosHome.home.activation
          && builtins.elem "hermesAgentSetup" zarosHome.home.activation.hermesAgentWorkflow.after
          && zarosHome.services.hermes-agent.hermesHomeFiles == { }
        ) "Hermes must seed a writable workflow after state setup without replacing learned files";
        assert lib.assertMsg (lib.all
          (
            package:
            builtins.elem package zarosHome.services.hermes-agent.extraPackages
            && lib.hasInfix (builtins.unsafeDiscardStringContext "${package}/bin") (
              lib.concatStringsSep "\n" zarosHome.systemd.user.services.hermes-backend.Service.Environment
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
        ) "Hermes backend must receive its Nix workflow tools without relying on an interactive shell";
        assert lib.assertMsg (
          zarosHome.services.hermes-agent.backend.mode == "dashboard"
          && zarosHome.services.hermes-agent.backend.host == "127.0.0.1"
        ) "Hermes dashboard must bind to loopback";
        assert lib.assertMsg (
          zarosHome.home.sessionVariables.HERMES_HOME == "${zarosHome.home.homeDirectory}/.hermes"
        ) "Hermes CLI must use the existing personal state directory";
        assert lib.assertMsg (builtins.hasAttr "hermes-backend" zarosHome.systemd.user.services)
          "Hermes dashboard must have a systemd user service";
        assert lib.assertMsg (
          zarosHome.services.hermes-agent.backend.sessionTokenFile
          == "${zarosHome.services.hermes-agent.hermesHome}/.backend-session-token"
          && builtins.hasAttr "hermesAgentSessionToken" zarosHome.home.activation
          && builtins.elem "hermesAgentSetup" zarosHome.home.activation.hermesAgentSessionToken.after
          && builtins.elem "reloadSystemd" zarosHome.home.activation.hermesAgentSessionToken.before
        ) "Hermes desktop and backend must share a token initialized after state setup";
        assert lib.assertMsg (
          !(hermesExternalToken.home.activation ? hermesAgentSessionToken)
          && !(hermesWithoutBackend.home.activation ? hermesAgentSessionToken)
          && !(hermesWithoutService.home.activation ? hermesAgentSessionToken)
          && !(hermesWithoutService.home.activation ? hermesAgentWorkflow)
        ) "Hermes must not provision caller-managed tokens or state for disabled services";
        assert lib.assertMsg (
          zarosHome.services.hermes-agent.environmentFiles == [ ]
          && zarosHome.services.hermes-agent.environment == { }
          && zarosHome.services.hermes-agent.authFile == null
        ) "Hermes must preserve existing runtime credentials";
        assert lib.assertMsg (
          !builtins.hasAttr "hermes-agent" zaros.systemd.services
          && !builtins.hasAttr "hermes-backend" zaros.systemd.services
        ) "Hermes must not run a second system-wide instance";
        assert lib.assertMsg zaros.users.users.${zarosUser}.linger
          "Hermes user service must survive logout";
        assert lib.assertMsg (lib.all hermesInactive [
          zarosWithoutHermes
          self.nixosConfigurations.saradomin.config
          self.nixosConfigurations.saradomin-vm.config
        ]) "Disabled Hermes must install no applications, start no services, and manage no state";
        pkgs.runCommand "hermes-agent-integration" { } "touch $out";
      mkZarosWeb =
        web:
        (inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit self inputs; };
          modules = [
            ../hosts/zaros
            { my.hermes-agent.web = lib.mapAttrs (_: value: lib.mkForce value) web; }
          ];
        }).config;
      hermesWebOtherPort = mkZarosWeb { publicUrl = "https://zaros.osiris-fish.ts.net:8443"; };
      hermesWebDisabled = mkZarosWeb { enable = false; };
      hermesWebAbsent =
        host:
        !(host.systemd.services ? hermes-tailnet)
        && !(host.home-manager.users.${host.my.user.name}.systemd.user.services ? hermes-web)
        && !((lib.attrByPath [ "sops" "secrets" ] { } host) ? hermes-web);
      hermesWebInvalid =
        web:
        let
          evaluated = builtins.tryEval (
            let
              candidate = mkZarosWeb web;
              assertions =
                candidate.assertions ++ candidate.home-manager.users.${candidate.my.user.name}.assertions;
              assertionResults = map (assertion: assertion.assertion) assertions;
            in
            builtins.deepSeq candidate.my.hermes-agent.web.port (
              builtins.deepSeq assertionResults (lib.all lib.id assertionResults)
            )
          );
        in
        !evaluated.success || !evaluated.value;
      hermesWebCheck =
        assert lib.assertMsg (lib.attrByPath [
          "my"
          "hermes-agent"
          "web"
          "enable"
        ] false zaros) "Zaros must explicitly select private Hermes web access";
        assert lib.assertMsg (
          zarosHome.systemd.user.services ? hermes-web
        ) "Private web access must have a separate authenticated user dashboard, preserving Desktop";
        assert lib.assertMsg (
          builtins.elem "HERMES_DASHBOARD_PUBLIC_URL=https://zaros.osiris-fish.ts.net" zarosHome.systemd.user.services.hermes-web.Service.Environment
          &&
            zarosHome.systemd.user.services.hermes-web.Service.EnvironmentFile
            == [ zaros.sops.secrets.hermes-web.path ]
          && zarosHome.services.hermes-agent.environmentFiles == [ ]
          && zarosHome.services.hermes-agent.environment == { }
          && !((zarosHome.services.hermes-agent.settings.dashboard or { }) ? public_url)
        ) "Web URL and SOPS credentials must be scoped to the web service, not shared Desktop state";
        assert lib.assertMsg (
          zaros.systemd.services ? hermes-tailnet
        ) "Hermes web must have a managed Tailscale proxy";
        assert lib.assertMsg (
          lib.hasInfix "serve --yes --https=443 http://127.0.0.1:9120" zaros.systemd.services.hermes-tailnet.serviceConfig.ExecStart
          && !(lib.hasInfix "--bg" zaros.systemd.services.hermes-tailnet.serviceConfig.ExecStart)
          && zaros.systemd.services.hermes-tailnet.serviceConfig.Restart == "always"
          && zaros.systemd.services.hermes-tailnet.serviceConfig.KillSignal == "SIGINT"
          && builtins.elem "tailscaled.service" zaros.systemd.services.hermes-tailnet.partOf
          && lib.hasInfix ".auth_required == true" zaros.systemd.services.hermes-tailnet.preStart
        ) "The proxy must own and recover a foreground route, and wait for authenticated Hermes";
        assert lib.assertMsg (
          lib.hasInfix "serve --yes --https=8443 http://127.0.0.1:9120" hermesWebOtherPort.systemd.services.hermes-tailnet.serviceConfig.ExecStart
          && lib.hasInfix "zaros.osiris-fish.ts.net." hermesWebOtherPort.systemd.services.hermes-tailnet.preStart
          && lib.all (a: a.assertion) hermesWebOtherPort.assertions
        ) "A port in publicUrl must configure HTTPS independently of the loopback backend port";
        assert lib.assertMsg (lib.all hermesWebAbsent [
          hermesWebDisabled
          zarosWithoutHermes
          self.nixosConfigurations.saradomin.config
          self.nixosConfigurations.saradomin-vm.config
        ]) "Disabling web access or Hermes must remove both web units and its decrypted secret";
        assert lib.assertMsg (
          zaros.networking.firewall.allowedTCPPorts == hermesWebDisabled.networking.firewall.allowedTCPPorts
          &&
            zaros.networking.firewall.trustedInterfaces
            == hermesWebDisabled.networking.firewall.trustedInterfaces
        ) "Hermes web must not widen firewall access or change Tailscale trust";
        assert lib.assertMsg (lib.all hermesWebInvalid [
          { publicUrl = "http://zaros.osiris-fish.ts.net"; }
          { publicUrl = "https://zaros.osiris-fish.ts.net/path"; }
          { publicUrl = "https://zaros.osiris-fish.ts.net:0"; }
          { publicUrl = "https://zaros.osiris-fish.ts.net:65536"; }
          { environmentFile = null; }
          { environmentFile = "/nix/store/unsafe-secret"; }
          { port = 0; }
          { port = zarosHome.services.hermes-agent.backend.port; }
        ]) "Unsafe origins, credentials paths and colliding listener ports must fail evaluation";
        assert lib.assertMsg (
          (zarosHome.systemd.user.services.hermes-web.Unit."X-Restart-Triggers" or [ ]) != [ ]
          && zaros.sops.secrets.hermes-web.owner == zarosUser
          && zaros.sops.secrets.hermes-web.mode == "0400"
        ) "Encrypted credential updates must restart the web listener, with private user-owned delivery";
        pkgs.runCommand "hermes-web-integration" { } "touch $out";
      mkHermesWebManifest =
        host:
        let
          home = host.home-manager.users.${host.my.user.name};
        in
        pkgs.writeText "hermes-web-runtime.json" (
          builtins.toJSON {
            private = home.systemd.user.services.hermes-backend.Service;
            web = home.systemd.user.services.hermes-web.Service;
            tokenFile = home.services.hermes-agent.backend.sessionTokenFile;
            privatePort = home.services.hermes-agent.backend.port;
            stateDirectories =
              (import "${inputs.hermes-agent}/nix/moduleCommon.nix" { inherit lib; }).stateSubdirs;
            publicUrl = host.my.hermes-agent.web.publicUrl;
            preStart = host.systemd.services.hermes-tailnet.preStart;
            tailscale = lib.getExe host.services.tailscale.package;
            curl = lib.getExe pkgs.curl;
            bash = lib.getExe pkgs.bash;
          }
        );
      hermesWebRuntimeCheck = pkgs.runCommand "hermes-web-runtime" { } (
        lib.concatMapStringsSep "\n"
          (
            host:
            let
              manifest = mkHermesWebManifest host;
            in
            ''
              ${pkgs.python3.withPackages (ps: [ ps.websockets ])}/bin/python3 \
                ${./features/programs/hermes-agent/config/test_web_runtime.py} ${manifest}
              ${pkgs.python3}/bin/python3 \
                ${./features/programs/hermes-agent/config/test_web_preflight.py} ${manifest}
            ''
          )
          [
            zaros
            hermesWebOtherPort
          ]
        + "\ntouch $out\n"
      );
      hermesDesktop = lib.findFirst (
        package: lib.getName package == "hermes-desktop"
      ) null zarosHome.home.packages;
      hermesBackendLauncher = builtins.head zarosHome.systemd.user.services.hermes-backend.Service.ExecStart;
      hermesRuntimeCheck = pkgs.runCommand "hermes-runtime-state" { } ''
        ${pkgs.python3}/bin/python3 ${./features/programs/hermes-agent/config}/test_runtime_state.py -v

        # Inspect the actual upstream-generated launchers, not copies of them.
        grep -Fq 'HERMES_DASHBOARD_SESSION_TOKEN' ${hermesBackendLauncher}
        grep -Fq '${zarosHome.services.hermes-agent.backend.sessionTokenFile}' ${hermesBackendLauncher}
        grep -Fq '${zarosHome.programs.hermes-agent.package}/bin/hermes' ${hermesBackendLauncher}
        grep -Fq 'HERMES_DESKTOP_REMOTE_TOKEN' ${hermesDesktop}/bin/hermes-desktop
        grep -Fq 'http://127.0.0.1:9119' ${hermesDesktop}/bin/hermes-desktop
        grep -Fq '${zarosHome.services.hermes-agent.backend.sessionTokenFile}' ${hermesDesktop}/bin/hermes-desktop
        touch $out
      '';
      mkZarosShell =
        shell:
        (inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit self inputs; };
          modules = [
            ../hosts/zaros
            { my.desktop.shell = lib.mkForce shell; }
          ];
        }).config;
      zarosCaelestia = mkZarosShell "caelestia";
      zarosNone = mkZarosShell "none";
      zarosCaelestiaHome = zarosCaelestia.home-manager.users.${zarosUser};
      zarosNoneHome = zarosNone.home-manager.users.${zarosUser};
      invalidShell = builtins.tryEval (
        builtins.deepSeq (mkZarosShell "invalid-shell").system.build.toplevel.drvPath true
      );
      shellProvidersCheck =
        assert lib.assertMsg zarosHome.programs.noctalia-shell.enable "Noctalia must be enabled";
        assert lib.assertMsg (!zarosHome.programs.caelestia.enable) "Noctalia must disable Caelestia";
        assert lib.assertMsg
          (builtins.hasAttr "noctalia" zarosHome.wayland.windowManager.hyprland.extraLuaFiles)
          "Noctalia startup Lua is missing";
        assert lib.assertMsg (
          !builtins.hasAttr "caelestia" zarosHome.systemd.user.services
        ) "Noctalia must not define Caelestia service";
        assert lib.assertMsg
          (builtins.elem zarosHome.programs.noctalia-shell.package zarosHome.home.packages)
          "Noctalia package must be directly installed";
        assert lib.assertMsg (
          !builtins.elem zarosHome.programs.caelestia.package zarosHome.home.packages
          && !builtins.elem zarosHome.programs.caelestia.cli.package zarosHome.home.packages
        ) "Noctalia must not install Caelestia packages";
        assert lib.assertMsg zarosCaelestiaHome.programs.caelestia.enable "Caelestia must be enabled";
        assert lib.assertMsg zarosCaelestiaHome.programs.caelestia.systemd.enable
          "Caelestia systemd must be enabled";
        assert lib.assertMsg zarosCaelestiaHome.programs.caelestia.cli.enable
          "Caelestia CLI must be enabled";
        assert lib.assertMsg (
          zarosCaelestiaHome.programs.caelestia.systemd.target == "wayland-session@hyprland.desktop.target"
        ) "Caelestia must target the UWSM Hyprland session";
        assert lib.assertMsg (
          !zarosCaelestiaHome.programs.noctalia-shell.enable
        ) "Caelestia must disable Noctalia";
        assert lib.assertMsg (
          !builtins.hasAttr "noctalia" zarosCaelestiaHome.wayland.windowManager.hyprland.extraLuaFiles
        ) "Caelestia must not define Noctalia Lua";
        assert lib.assertMsg (builtins.hasAttr "caelestia" zarosCaelestiaHome.systemd.user.services)
          "Caelestia service is missing";
        assert lib.assertMsg (
          zarosCaelestiaHome.systemd.user.services.caelestia.Service.ExecStart
          == [ "${zarosCaelestiaHome.programs.caelestia.package}/bin/caelestia-shell" ]
        ) "Caelestia ExecStart is not the configured shell";
        assert lib.assertMsg (
          zarosCaelestiaHome.systemd.user.services.caelestia.Unit.After
          == [ zarosCaelestiaHome.programs.caelestia.systemd.target ]
        ) "Caelestia After target mismatch";
        assert lib.assertMsg (
          zarosCaelestiaHome.systemd.user.services.caelestia.Unit.PartOf
          == [ zarosCaelestiaHome.programs.caelestia.systemd.target ]
        ) "Caelestia PartOf target mismatch";
        assert lib.assertMsg (
          zarosCaelestiaHome.systemd.user.services.caelestia.Install.WantedBy
          == [ zarosCaelestiaHome.programs.caelestia.systemd.target ]
        ) "Caelestia WantedBy target mismatch";
        assert lib.assertMsg (
          builtins.elem zarosCaelestiaHome.programs.caelestia.package zarosCaelestiaHome.home.packages
          && builtins.elem zarosCaelestiaHome.programs.caelestia.cli.package zarosCaelestiaHome.home.packages
        ) "Caelestia packages must be directly installed";
        assert lib.assertMsg (
          !builtins.elem zarosCaelestiaHome.programs.noctalia-shell.package zarosCaelestiaHome.home.packages
        ) "Caelestia must not install Noctalia";
        assert lib.assertMsg (
          !zarosNoneHome.programs.noctalia-shell.enable && !zarosNoneHome.programs.caelestia.enable
        ) "none must disable both providers";
        assert lib.assertMsg (
          !builtins.elem zarosNoneHome.programs.noctalia-shell.package zarosNoneHome.home.packages
          && !builtins.elem zarosNoneHome.programs.caelestia.package zarosNoneHome.home.packages
          && !builtins.elem zarosNoneHome.programs.caelestia.cli.package zarosNoneHome.home.packages
        ) "none must install neither provider";
        assert lib.assertMsg (
          !builtins.hasAttr "noctalia" zarosNoneHome.wayland.windowManager.hyprland.extraLuaFiles
          && !builtins.hasAttr "caelestia" zarosNoneHome.systemd.user.services
        ) "none must have no provider startup";
        assert lib.assertMsg (lib.all (command: command == null) (
          lib.attrValues zarosNoneHome.my.desktop.shellCommands
        )) "none commands must all be null";
        assert lib.assertMsg (
          zarosHome.my.desktop.shellCommands == zarosHome.my.desktop.shellProviders.noctalia.commands
        ) "Noctalia command registry mismatch";
        assert lib.assertMsg (
          zarosCaelestiaHome.my.desktop.shellCommands
          == zarosCaelestiaHome.my.desktop.shellProviders.caelestia.commands
        ) "Caelestia command registry mismatch";
        assert lib.assertMsg (!invalidShell.success) "Invalid shell selector must fail evaluation";
        pkgs.runCommand "shell-providers" { } "touch $out";
      writeLuaFiles =
        variant: home:
        lib.mapAttrs' (
          name: file:
          let
            fileName = "${variant}-${name}.lua";
          in
          lib.nameValuePair fileName (pkgs.writeText fileName file.content)
        ) home.wayland.windowManager.hyprland.extraLuaFiles;
      luaFiles =
        (writeLuaFiles "noctalia" zarosHome)
        // (writeLuaFiles "caelestia" zarosCaelestiaHome)
        // (writeLuaFiles "none" zarosNoneHome);
      luaCheck = pkgs.runCommand "zaros-generated-lua" { } ''
        mkdir -p $out
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: file: "cp ${file} $out/${name}") luaFiles)}
        ${pkgs.lua5_4}/bin/luac -p $out/*.lua
      '';
      repositoryStructure =
        let
          featureEntries = builtins.readDir ../modules/features;
          hostEntries = builtins.readDir ../hosts;
          featureDomains = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") featureEntries);
          topLevelHosts = builtins.attrNames (lib.filterAttrs (_: type: type == "directory") hostEntries);
          directFeatureNix = lib.filter (
            name: featureEntries.${name} == "regular" && lib.hasSuffix ".nix" name
          ) (builtins.attrNames featureEntries);
        in
        assert lib.assertMsg (
          featureDomains == [
            "applications"
            "desktop"
            "programs"
            "services"
            "system"
          ]
        ) "feature domains must be exactly applications, desktop, programs, services, system";
        assert lib.assertMsg (
          directFeatureNix == [ ]
        ) "modules/features must not contain regular .nix modules directly";
        assert lib.assertMsg (
          topLevelHosts == [
            "macbook"
            "saradomin"
            "saradomin-vm"
            "zaros"
          ]
        ) "top-level host directories must be exactly macbook, saradomin, saradomin-vm, zaros";
        assert lib.assertMsg (!builtins.pathExists ../modules/hosts) "legacy modules/hosts must not exist";
        pkgs.runCommand "repository-structure" { } "touch $out";
    in
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
        flakeFormatter = true;
        flakeCheck = true;
      };

      checks = {
        repository-structure = repositoryStructure;
      }
      // (lib.optionalAttrs linux {
        zaros = self.nixosConfigurations.zaros.config.system.build.toplevel;
        saradomin = self.nixosConfigurations.saradomin.config.system.build.toplevel;
        saradomin-vm = self.nixosConfigurations."saradomin-vm".config.system.build.toplevel;
        saradomin-lan-dns = saradominLanDnsCheck;
        saradomin-adguard-home = saradominAdGuardHomeCheck;
        sops-environment = sopsEnvironmentCheck;
        generated-lua = luaCheck;
        shell-providers = shellProvidersCheck;
        hermes-agent = hermesAgentCheck;
        hermes-runtime-state = hermesRuntimeCheck;
        hermes-web = hermesWebCheck;
        hermes-web-runtime = hermesWebRuntimeCheck;
      })
      // (lib.optionalAttrs darwin {
        macbook = self.darwinConfigurations.macbook.config.system.build.toplevel;
      });
    };
}
