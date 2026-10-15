{ inputs, ... }:
{
  # One discovered feature; internal role implementations are not auto-imported.
  # Registering both roles does not activate either on an unselected host.
  imports = [
    ./config/server.nix
    ./config/client.nix
  ];

  perSystem = { pkgs, ... }: {
    packages.ai-memory = inputs.ai-memory.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
