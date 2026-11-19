{ lib, ... }:
let
  toolchains = import ./config/toolchains.nix;
in
{
  # README "Language toolchains" shows host and dev shell use.
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
