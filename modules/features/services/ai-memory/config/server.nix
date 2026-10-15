{ inputs, self, ... }:
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
      imports = [ inputs.ai-memory.nixosModules.default ];

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
          default = defaultToken;
          description = "Runtime bearer token file; the default is minted once. A SOPS-managed alternative must be readable by the service user.";
        };
      };

      config = {
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
          memoryMax = "1G";
          tasksMax = 128;
          settings = {
            allowed_hosts = [
              "localhost"
              "127.0.0.1"
              cfg.hostName
            ];
            embedding_provider = "none";
            capture_assistant = false;
            auth = {
              bearer_token_file = token;
              secure_cookie = true;
            };
            auto_improve = {
              require_approval = true;
              scheduler.enabled = false;
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
          test -r ${lib.escapeShellArg token}
          grep -q '[^[:space:]]' ${lib.escapeShellArg token}
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
      assert settings.embedding_provider == "none";
      assert settings.auth.bearer_token_file == cfg.sops.secrets.ai-memory-token.path;
      assert cfg.sops.secrets.ai-memory-token.owner == cfg.services.ai-memory.user;
      assert cfg.sops.secrets.ai-memory-token.mode == "0400";
      assert settings.auth.secure_cookie;
      assert !settings.auto_improve.scheduler.enabled;
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
          if FIXTURE_TOKEN="$TMPDIR/missing-token" ${tokenGuard}; then
            echo 'Missing token must block server startup' >&2
            exit 1
          fi
          printf ' \n' > "$TMPDIR/blank-token"
          if FIXTURE_TOKEN="$TMPDIR/blank-token" ${tokenGuard}; then
            echo 'Blank token must block server startup' >&2
            exit 1
          fi
          printf 'fixture-token\n' > "$TMPDIR/valid-token"
          FIXTURE_TOKEN="$TMPDIR/valid-token" ${tokenGuard}
          node ${./test-server.mjs} \
            ${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.ai-memory} \
            ${fixtureConfig} "$TMPDIR"
          touch "$out"
        '';
  };
}
