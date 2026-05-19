{ inputs, self, ... }:
{
  flake.nixosConfigurations.zaros = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [ self.nixosModules.zaros ];
  };
}
