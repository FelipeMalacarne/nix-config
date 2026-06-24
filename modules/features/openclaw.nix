{ inputs, ... }:
let
  module =
    { pkgs, config, ... }:
    let
      user = config.my.user.name;
    in
    {
      sops.secrets.openclaw-gateway-token = {
        owner = user;
        mode = "0400";
      };

      home-manager.users.${user} =
        { ... }:
        {
          home.packages = [
            inputs.nix-openclaw.packages.${pkgs.stdenv.hostPlatform.system}.openclaw
          ];

          home.file.".openclaw/openclaw.json".text =
            (builtins.toJSON {
              gateway = {
                mode = "remote";
                remote = {
                  url = "wss://claw.ftm.dev.br";
                  token = {
                    source = "file";
                    provider = "sops";
                    id = config.sops.secrets.openclaw-gateway-token.path;
                  };
                };
              };
            })
            + "\n";
        };
    };
in
{
  flake.nixosModules.openclaw = module;
  flake.darwinModules.openclaw = module;
}
