{ inputs, self, ... }:
{
  # One discovered feature; internal role implementations are not auto-imported.
  # Registering both roles does not activate either on an unselected host.
  imports = [
    ./config/server.nix
    ./config/client.nix
    ./config/backup.nix
  ];

  perSystem = { lib, pkgs, ... }: {
    packages.ai-memory =
      inputs.ai-memory.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
        {
          src = pkgs.applyPatches {
            name = "ai-memory-reviewed-source";
            src = inputs.ai-memory;
            patches = [
              ./config/upstream-client-fixes.patch
              ./config/opencode-turn-consolidation.patch
            ];
            patchFlags = [
              "-p1"
              "--fuzz=0"
            ];
          };
        };
    checks.ai-memory-consolidation =
      pkgs.runCommand "ai-memory-consolidation"
        {
          nativeBuildInputs = [
            pkgs.nodejs
            pkgs.git
          ];
          __darwinAllowLocalNetworking = true;
        }
        ''
          node ${./config/test-consolidation.mjs} \
            ${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.ai-memory} "$TMPDIR"
          touch "$out"
        '';
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
          python3 ${./config/test-import-copilot.py} ${./config/import-copilot.py} \
            ${lib.getExe self.packages.${pkgs.stdenv.hostPlatform.system}.ai-memory}
          touch "$out"
        '';
  };
}
