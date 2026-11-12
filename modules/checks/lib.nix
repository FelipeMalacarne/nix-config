{ inputs, self, ... }:
{
  # Shared check helpers, available to every perSystem module as arguments.
  perSystem =
    { lib, pkgs, ... }:
    {
      _module.args = {
        # Synthetic NixOS configurations; see ./config/fixtures.nix.
        fixtures = import ./config/fixtures.nix { inherit inputs self; };

        # Evaluates Home Manager modules for a throwaway user.
        evalHome =
          modules:
          (inputs.home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              {
                home = {
                  username = "feature-check";
                  homeDirectory = "/tmp/feature-check";
                  stateVersion = "24.11";
                };
              }
            ]
            ++ modules;
          }).config;

        # Takes NixOS-style `{ assertion, message }` records. Builds an empty
        # marker when all hold; otherwise fails evaluation listing every
        # failed message, not just the first.
        mkAssertCheck =
          name: assertions:
          let
            failed = lib.filter (check: !check.assertion) assertions;
          in
          if failed == [ ] then
            pkgs.runCommand name { } "touch $out"
          else
            throw "${name} failed:\n${lib.concatMapStringsSep "\n" (check: "- ${check.message}") failed}";
      };
    };
}
