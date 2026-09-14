{ inputs, ... }:
let
  homeModule =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.hermes-agent;
      tokenFile = "${cfg.hermesHome}/.backend-session-token";
    in
    {
      # Capture flake inputs here; Home Manager does not inherit specialArgs.
      imports = [ inputs.hermes-agent.homeManagerModules.default ];

      options.my.hermes-agent.enable = lib.mkEnableOption "personal Hermes Agent";

      config = lib.mkIf config.my.hermes-agent.enable {
        programs.hermes-agent = {
          enable = true;
          desktop.enable = lib.mkDefault true;
        };

        services.hermes-agent = {
          enable = true;
          extraPackages =
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
            ]
            ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.systemd ];
          # Only the dashboard is needed; messaging can be enabled separately.
          gateway.enable = lib.mkDefault false;
          backend = {
            mode = lib.mkDefault "dashboard";
            host = lib.mkDefault "127.0.0.1";
            sessionTokenFile = lib.mkDefault tokenFile;
          };
          settings = {
            model.default = "openai/gpt-5.6-sol";
            memory = {
              memory_enabled = true;
              user_profile_enabled = true;
            };
            skills.write_approval = true;
            # Assess flagged commands automatically; prompt when uncertain.
            approvals.mode = "smart";
            security.redact_secrets = true;
            agent.verify_on_stop = true;
            checkpoints.enabled = true;
          };
          # Leave environmentFiles/authFile unset to preserve existing credentials.
        };

        home.activation = lib.mkIf cfg.enable {
          hermesAgentWorkflow = lib.hm.dag.entryBetween [ "reloadSystemd" ] [ "hermesAgentSetup" ] ''
            $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${./hermes-agent/config/runtime-state.py} seed-skill \
              ${./hermes-agent/config/nix-system-workflow/SKILL.md} \
              ${lib.escapeShellArg "${cfg.hermesHome}/skills/nix-system-workflow/SKILL.md"}
          '';
          # A caller supplying a SOPS/other token path owns its provisioning.
          hermesAgentSessionToken =
            lib.mkIf (cfg.backend.mode != "none" && cfg.backend.sessionTokenFile == tokenFile)
              (
                lib.hm.dag.entryBetween [ "reloadSystemd" ] [ "hermesAgentSetup" ] ''
                  $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${./hermes-agent/config/runtime-state.py} ensure-token \
                    ${lib.escapeShellArg tokenFile}
                ''
              );
        };
      };
    };
in
{
  flake.modules.homeManager.hermes-agent = homeModule;

  flake.modules.nixos.hermes-agent =
    { config, lib, ... }:
    {
      imports = [ ./hermes-agent/config/web.nix ];

      options.my.hermes-agent.enable = lib.mkEnableOption "personal Hermes Agent";

      config = {
        home-manager.users.${config.my.user.name} = {
          imports = [ homeModule ];
          my.hermes-agent.enable = config.my.hermes-agent.enable;
        };
        users.users.${config.my.user.name}.linger = lib.mkIf config.my.hermes-agent.enable true;
      };
    };
}
