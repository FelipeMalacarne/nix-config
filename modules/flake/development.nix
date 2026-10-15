{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShellNoCC {
        name = "nix-config-validation";
        packages = with pkgs; [
          gnumake
          git
          nix
          nixfmt
          statix
          deadnix
          shellcheck
          jq
          ripgrep
          fd
        ];
      };
    };
}
