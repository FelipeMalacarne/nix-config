{ inputs, self, ... }:
{
  flake.nixosConfigurations.zaros = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [ self.nixosModules.zaros ];
  };
}
