{ inputs, self, ... }:
{
  # RecompLauncher installs and updates the recomps itself, from each developer's
  # GitHub release, and sets them up from the user's own game dump; Nix only
  # provides the launcher.
  flake.modules.nixos.recomplauncher =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [ inputs.recomplauncher.overlays.default ];

      # Windows recomps run through umu and Proton, which need 32-bit graphics.
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      # Game shortcuts launch it from the system profile path.
      environment.systemPackages = [ pkgs.recomplauncher ];
    };

  perSystem =
    {
      lib,
      fixtures,
      mkAssertCheck,
      ...
    }:
    let
      hasLauncher = host: lib.any (p: lib.getName p == "recomplauncher") host.environment.systemPackages;
      selected = fixtures.mkFeatureConfig [ self.modules.nixos.recomplauncher ];
    in
    {
      checks.recomplauncher = mkAssertCheck "recomplauncher" [
        {
          assertion = !hasLauncher fixtures.baseOnly;
          message = "RecompLauncher must not be installed without importing the aspect.";
        }
        {
          assertion = hasLauncher selected && selected.hardware.graphics.enable32Bit;
          message = "Importing recomplauncher must install the launcher with 32-bit graphics for Proton.";
        }
      ];
    };
}
