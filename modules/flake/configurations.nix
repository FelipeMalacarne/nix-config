{ inputs, self, ... }:
{
  flake.nixosConfigurations = {
    zaros = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs self; };
      modules = [ ../../hosts/zaros ];
    };
    saradomin = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs self; };
      modules = [ ../../hosts/saradomin ];
    };
    "saradomin-vm" = inputs.nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs self; };
      modules = [ ../../hosts/saradomin-vm ];
    };
  };

  flake.darwinConfigurations.macbook = inputs.darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    specialArgs = { inherit inputs self; };
    modules = [ ../../hosts/macbook ];
  };
}
