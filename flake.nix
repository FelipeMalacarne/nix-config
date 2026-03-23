# flake.nix
{
  description = "Felipe's system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # noctalia-qs must be top-level so follows overrides apply correctly
    # and only one nixpkgs version ends up in the closure
    noctalia-qs = {
      url = "github:noctalia-dev/noctalia-qs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.noctalia-qs.follows = "noctalia-qs";
    };

    nvim-config.url = "github:FelipeMalacarne/nvim";
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    {
      nixosConfigurations = {
        zaros = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/zaros
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = { inherit inputs; };
            }
          ];
        };
      };
    };
}
