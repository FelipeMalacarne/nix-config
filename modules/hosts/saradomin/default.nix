{ inputs, self, ... }:
{
  flake.nixosConfigurations.saradomin = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ self.nixosModules.saradomin ];
  };
}
