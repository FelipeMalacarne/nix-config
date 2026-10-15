{ self, ... }:
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    let
      # Configuration outputs remain explicit in flake/configurations.nix.
      # Only validation/build enumeration is mechanical.
      configurations = (self.nixosConfigurations or { }) // (self.darwinConfigurations or { });
      native = lib.filterAttrs (_: host: host.pkgs.stdenv.hostPlatform.system == system) configurations;
      closures = lib.mapAttrs (_: host: host.config.system.build.toplevel) native;
    in
    {
      checks = closures;
      # Make consumes this same native set without maintaining host names or
      # interpreting evaluated text as shell source.
      packages.host-closures =
        assert lib.assertMsg (closures != { }) "No native host closures are configured for ${system}";
        pkgs.linkFarm "native-host-closures" (
          lib.mapAttrsToList (name: path: { inherit name path; }) closures
        );
    };
}
