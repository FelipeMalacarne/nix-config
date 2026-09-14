{ inputs, ... }:
let
  homeModule =
    { config, lib, ... }:
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
          # Only the dashboard is needed; messaging can be enabled separately.
          gateway.enable = lib.mkDefault false;
          backend = {
            mode = lib.mkDefault "dashboard";
            host = lib.mkDefault "127.0.0.1";
          };
          settings.model.default = "openai/gpt-5.6-sol";
          # Leave environmentFiles/authFile unset to preserve existing credentials.
        };
      };
    };
in
{
  flake.modules.homeManager.hermes-agent = homeModule;

  flake.modules.nixos.hermes-agent =
    { config, lib, ... }:
    {
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
