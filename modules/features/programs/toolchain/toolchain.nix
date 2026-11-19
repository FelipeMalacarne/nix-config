{ lib, ... }:
let
  toolchains = import ./config/toolchains.nix;
in
{
  # A host selects a stack by importing `toolchain-<name>` into its Home
  # Manager user. Another flake reuses it as a dev shell:
  #   devShells.default = pkgs.mkShell {
  #     inputsFrom = [ nix-config.devShells.${system}.laravel ];
  #   };
  flake.modules.homeManager = lib.mapAttrs' (
    name: packages:
    lib.nameValuePair "toolchain-${name}" (
      { pkgs, ... }:
      {
        home.packages = packages pkgs;
      }
    )
  ) toolchains;

  perSystem =
    { pkgs, ... }:
    {
      devShells = lib.mapAttrs (
        name: packages:
        pkgs.mkShell {
          inherit name;
          packages = packages pkgs;
        }
      ) toolchains;
    };
}
