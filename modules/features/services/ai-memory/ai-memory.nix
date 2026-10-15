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
    packages.ai-memory-import-copilot = pkgs.writeShellApplication {
      name = "ai-memory-import-copilot";
      runtimeInputs = [
        pkgs.python3
        pkgs.sops
      ];
      text = ''
        exec python3 ${./config/import-copilot.py} "$@"
      '';
    };
    checks.ai-memory-copilot-import =
      pkgs.runCommand "ai-memory-copilot-import"
        {
          nativeBuildInputs = [
            pkgs.python3
            pkgs.sops
            pkgs.age
          ];
        }
        ''
          export HOME="$TMPDIR/home"
          mkdir -p "$HOME"
          python3 ${./config/test-import-copilot.py} ${./config/import-copilot.py}
          touch "$out"
        '';
  };
}
