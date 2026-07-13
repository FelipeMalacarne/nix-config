{ inputs, ... }:
let
  homeModule =
    { pkgs, ... }:
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
                id = "/run/secrets/openclaw-gateway-token";
              };
            };
          };
        })
        + "\n";
    };
in
{
  flake.homeModules.openclaw = homeModule;
}
