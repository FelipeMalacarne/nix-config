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

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-colors.url = "github:Misterio77/nix-colors";

    nur.url = "github:nix-community/NUR";
    millennium.url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      darwin,
      nur,
      sops-nix,
      ...
    }@inputs:
    {
      darwinConfigurations = {
        macbook = darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/macbook
            home-manager.darwinModules.home-manager
            {
              home-manager.extraSpecialArgs = { inherit inputs; };
              # 2. APPLY THE OVERLAY FOR MACOS
              nixpkgs.overlays = [ nur.overlays.default ];
            }
          ];
        };
      };

      nixosConfigurations = {
        zaros = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/zaros
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = { inherit inputs; };
              nixpkgs.overlays = [ nur.overlays.default ];
            }
          ];
        };

        saradomin-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/saradomin-vm
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = { inherit inputs; };
              nixpkgs.overlays = [ nur.overlays.default ];
            }
          ];
        };

        saradomin = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/saradomin
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager.extraSpecialArgs = { inherit inputs; };
              nixpkgs.overlays = [ nur.overlays.default ];
            }
          ];
        };
      };
    };
}
