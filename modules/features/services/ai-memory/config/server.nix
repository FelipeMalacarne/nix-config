{
  config,
  inputs,
  self,
  ...
}:
let
  registry = config.flake.modules;
in
{
  flake.modules.nixos.ai-memory-server =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.ai-memory-server;
      service = config.services.ai-memory;
      defaultToken = "${service.dataDir}/auth-tokens/default";
      token = cfg.tokenFile;
    in
    {
      imports = [
        inputs.ai-memory.nixosModules.default
        registry.nixos.sops
      ];

      options.my.ai-memory-server = {
        hostName = lib.mkOption {
          type = lib.types.strMatching "[a-z0-9-]+([.][a-z0-9-]+)+";
          description = "This server's full MagicDNS name, allowed by the HTTP host guard.";
        };
        httpsPort = lib.mkOption {
          type = lib.types.port;
          default = 8443;
          description = "Dedicated private Tailscale Serve HTTPS port; never Funnel.";
        };
        tokenFile = lib.mkOption {
          type = lib.types.strMatching "/.+";
          default = config.sops.secrets.ai-memory-token.path;
          description = "Runtime bearer token file, defaulting to the feature's SOPS-managed credential.";
        };
      };

      config = {
        sops.secrets.ai-memory-token = (import ./credential.nix) // {
          owner = service.user;
          group = service.group;
          restartUnits = [ "ai-memory.service" ];
        };
        sops.secrets.ai-memory-copilot = {
          sopsFile = ../../../../../secrets/ai-memory-copilot.yaml;
          key = "github_token";
          owner = service.user;
          group = service.group;
          mode = "0400";
        };
        sops.templates."ai-memory-copilot.env" = {
          content = "COPILOT_GITHUB_TOKEN=${config.sops.placeholder.ai-memory-copilot}\n";
          owner = service.user;
          group = service.group;
          mode = "0400";
          restartUnits = [ "ai-memory.service" ];
        };
        assertions = [
          {
            assertion = config.services.tailscale.enable;
            message = "ai-memory-server requires an explicitly selected Tailscale service.";
          }
          {
            assertion = !(lib.hasPrefix "${builtins.storeDir}/" token);
            message = "ai-memory-server tokenFile must be a private runtime file, never a Nix store path.";
          }
        ];

        services.ai-memory = {
          enable = true;
          bind = "127.0.0.1";
          openFirewall = false;
          # Headroom for in-process CPU embeddings; this is a ceiling, not a reservation.
          memoryMax = "2G";
          tasksMax = 128;
          environmentFile = config.sops.templates."ai-memory-copilot.env".path;
          settings = {
            allowed_hosts = [
              "localhost"
              "127.0.0.1"
              cfg.hostName
            ];
            embedding_provider = "local";
            # Copilot subscription allowance only: no paid-provider fallback.
            # Only a runtime SOPS template carries the GitHub bootstrap token.
            llm_provider = "copilot";
            llm_reasoning_effort = "low";
            llm_fallbacks = [ ];
            consolidate_on_session_end = true;
            consolidation = {
              max_input_tokens = 16000;
              max_output_tokens = 2000;
            };
            capture_assistant = false;
            auth = {
              bearer_token_file = token;
              secure_cookie = true;
            };
            auto_improve = {
              require_approval = true;
              on_session_end = false;
              scheduler = {
                enabled = true;
                interval_secs = 3600;
                max_sessions_per_tick = 1;
                min_session_age_secs = 600;
              };
            };
            dream.enabled = false;
            profile.enabled = "off";
          };
        };

        # Mint once on the server, never during Nix evaluation or in the store.
        # An existing token (including a provisioned SOPS symlink) is preserved.
        systemd.services.ai-memory.preStart = ''
          umask 077
          ${lib.optionalString (token == defaultToken) ''
            mkdir -p ${lib.escapeShellArg "${service.dataDir}/auth-tokens"}
            if [ ! -e ${lib.escapeShellArg token} ]; then
              if [ -e ${lib.escapeShellArg "${service.dataDir}/auth-tokens/.initialized"} ] ||
                 [ -e ${lib.escapeShellArg "${service.dataDir}/db/memory.sqlite"} ]; then
                echo 'ai-memory bearer missing: restore the credential; refusing silent rotation.' >&2
                exit 1
              fi
              ${pkgs.openssl}/bin/openssl rand -hex 32 > ${lib.escapeShellArg "${token}.new"}
              mv ${lib.escapeShellArg "${token}.new"} ${lib.escapeShellArg token}
            fi
            touch ${lib.escapeShellArg "${service.dataDir}/auth-tokens/.initialized"}
          ''}
          # Upstream treats an unreadable/blank token file as no loaded bearer.
          # Fail closed before starting, including for externally managed tokens.
          if ! test -r ${lib.escapeShellArg token} || ! grep -q '[^[:space:]]' ${lib.escapeShellArg token}; then
            echo 'ai-memory bearer is missing, unreadable or blank; refusing unauthenticated startup.' >&2
            exit 1
          fi
          case "''${COPILOT_GITHUB_TOKEN:-}" in
            ""|UNCONFIGURED|*[!A-Za-z0-9_]*)
              echo 'Copilot token missing or unconfigured; import it with ai-memory-import-copilot before activation.' >&2
              exit 1
              ;;
          esac
        '';
        systemd.services.ai-memory.path = [ pkgs.gnugrep ];

        # Foreground Serve is scoped to this unit's lifetime. Never reset the
        # node's Serve configuration or overwrite an already occupied listener.
        systemd.services.ai-memory-https = {
          description = "Private ai-memory HTTPS via Tailscale Serve";
          wantedBy = [ "multi-user.target" ];
          after = [
            "tailscaled.service"
            "ai-memory.service"
          ];
          # Keep the proxy independently supervised: a backend restart must not
          # stop HTTPS permanently through a Requires= dependency.
          wants = [
            "tailscaled.service"
            "ai-memory.service"
          ];
          path = [
            config.services.tailscale.package
            pkgs.jq
          ];
          preStart = ''
            tailscale serve status --json | jq -e \
              --arg port ${lib.escapeShellArg (toString cfg.httpsPort)} \
              '(.TCP[$port] // null) == null' > /dev/null
          '';
          serviceConfig = {
            ExecStart = "${config.services.tailscale.package}/bin/tailscale serve --yes --https=${toString cfg.httpsPort} http://127.0.0.1:${toString service.port}";
            Restart = "always";
            RestartSec = "15s";
          };
        };
      };
    };

  perSystem = { lib, pkgs, ... }: {
    checks.ai-memory-server =
      let
        cfg = self.nixosConfigurations.saradomin.config;
        settings = cfg.services.ai-memory.settings;
        pruneNulls =
          value:
          if builtins.isAttrs value then
            lib.filterAttrs (_: v: v != null) (lib.mapAttrs (_: v: pruneNulls v) value)
          else
            value;
        fixtureConfig = (pkgs.formats.toml { }).generate "ai-memory-server-fixture.toml" (
          pruneNulls (
            settings
            // {
              auth = settings.auth // {
                bearer_token_file = "fixture-auth-token";
              };
            }
          )
        );
        tokenGuard = pkgs.writeShellScript "ai-memory-fixture-token-guard" (
          lib.replaceStrings
            [ (lib.escapeShellArg cfg.my.ai-memory-server.tokenFile) ]
            [ ''"$FIXTURE_TOKEN"'' ]
            cfg.systemd.services.ai-memory.preStart
        );
      in
      assert cfg.services.ai-memory.enable;
      assert cfg.services.ai-memory.bind == "127.0.0.1";
      assert !cfg.services.ai-memory.openFirewall;
      assert cfg.services.ai-memory.enableWeb;
      assert lib.hasInfix "--enable-web" cfg.systemd.services.ai-memory.serviceConfig.ExecStart;
      assert cfg.services.ai-memory.memoryMax == "2G";
      assert settings.embedding_provider == "local";
      assert settings.llm_provider == "copilot";
      assert settings.llm_model == null;
      assert settings.llm_base_url == null;
      assert settings.llm_reasoning_effort == "low";
      assert settings.llm_fallbacks == [ ];
      assert settings.consolidate_on_session_end;
      assert settings.consolidation.max_input_tokens == 16000;
      assert settings.consolidation.max_output_tokens == 2000;
      assert settings.auth.bearer_token_file == cfg.sops.secrets.ai-memory-token.path;
      assert cfg.sops.secrets.ai-memory-token.owner == cfg.services.ai-memory.user;
      assert cfg.sops.secrets.ai-memory-token.mode == "0400";
      assert settings.auth.secure_cookie;
      assert cfg.sops.secrets.ai-memory-copilot.key == "github_token";
      assert cfg.sops.secrets.ai-memory-copilot.owner == cfg.services.ai-memory.user;
      assert cfg.sops.secrets.ai-memory-copilot.mode == "0400";
      assert cfg.sops.templates."ai-memory-copilot.env".owner == cfg.services.ai-memory.user;
      assert cfg.sops.templates."ai-memory-copilot.env".mode == "0400";
      assert cfg.sops.templates."ai-memory-copilot.env".restartUnits == [ "ai-memory.service" ];
      assert
        cfg.sops.templates."ai-memory-copilot.env".content
        == "COPILOT_GITHUB_TOKEN=${cfg.sops.placeholder.ai-memory-copilot}\n";
      assert !(cfg.systemd.services.ai-memory.environment ? COPILOT_GITHUB_TOKEN);
      assert cfg.services.ai-memory.environmentFile == cfg.sops.templates."ai-memory-copilot.env".path;
      assert
        cfg.systemd.services.ai-memory.serviceConfig.EnvironmentFile
        == "-${cfg.sops.templates."ai-memory-copilot.env".path}";
      assert settings.auto_improve.scheduler.enabled;
      assert settings.auto_improve.scheduler.interval_secs == 3600;
      assert settings.auto_improve.scheduler.max_sessions_per_tick == 1;
      assert settings.auto_improve.scheduler.min_session_age_secs == 600;
      assert !settings.auto_improve.on_session_end;
      assert settings.auto_improve.require_approval;
      assert !settings.dream.enabled;
      assert settings.profile.enabled == "off";
      assert cfg.systemd.services.ai-memory.serviceConfig.ProtectSystem == "strict";
      assert lib.hasInfix "--https=8443 http://127.0.0.1:49374"
        cfg.systemd.services.ai-memory-https.serviceConfig.ExecStart;
      assert cfg.systemd.services.ai-memory-https.serviceConfig.Restart == "always";
      assert !(self.nixosConfigurations.saradomin-vm.config.services ? ai-memory);
      pkgs.runCommand "ai-memory-server-policy"
        {
          nativeBuildInputs = [
            pkgs.nodejs
            pkgs.git
          ];
          __darwinAllowLocalNetworking = true;
        }
        ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"
          if FIXTURE_TOKEN="$TMPDIR/missing-token" COPILOT_GITHUB_TOKEN=ghu_fixture ${tokenGuard}; then
            echo 'Missing token must block server startup' >&2
            exit 1
          fi
          printf ' \n' > "$TMPDIR/blank-token"
          if FIXTURE_TOKEN="$TMPDIR/blank-token" COPILOT_GITHUB_TOKEN=ghu_fixture ${tokenGuard}; then
            echo 'Blank token must block server startup' >&2
            exit 1
          fi
          printf 'fixture-token\n' > "$TMPDIR/valid-token"
          if FIXTURE_TOKEN="$TMPDIR/valid-token" COPILOT_GITHUB_TOKEN=UNCONFIGURED ${tokenGuard}; then
            echo 'Unconfigured Copilot token must block server startup' >&2
            exit 1
          fi
          if FIXTURE_TOKEN="$TMPDIR/valid-token" COPILOT_GITHUB_TOKEN= ${tokenGuard}; then
            echo 'Missing Copilot token must block server startup' >&2
            exit 1
          fi
          if FIXTURE_TOKEN="$TMPDIR/valid-token" COPILOT_GITHUB_TOKEN='invalid token' ${tokenGuard}; then
            echo 'Invalid Copilot token must block server startup' >&2
            exit 1
          fi
          FIXTURE_TOKEN="$TMPDIR/valid-token" COPILOT_GITHUB_TOKEN=ghu_fixture ${tokenGuard}
          node ${./test-server.mjs} \
            ${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.ai-memory} \
            ${fixtureConfig} "$TMPDIR"
          touch "$out"
        '';
  };
}
