{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-qtutils.url = "github:hyprwm/hyprland-qtutils"; # NOTE Temp until fixed upstream
  };

  outputs = { 
    self,
    nixpkgs,
    nixpkgs-stable,
    ... 
  } @ inputs:
  let
    # User configuration
    username = "felipemalacarne"; 
    terminal = "kitty"; # alacritty or kitty
    wallpaper = "cyberpunk.png"; # see modules/themes/wallpapers

    # System configuration
    hostname = "zaros"; # CHOOSE A HOSTNAME HERE (default is fine)
    locale = "pt_BR";
    timezone = "America/Sao_Paulo"; # REPLACE THIS WITH YOUR TIMEZONE
    kbdLayout = "us"; # REPLACE THIS WITH YOUR KEYBOARD LAYOUT

    system = "x86_64-linux"; # most users will be on 64 bit pcs (unless yours is ancient)
    lib = nixpkgs.lib;
    pkgs-stable = _final: _prev: {
      stable = import nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
        config.nvidia.acceptLicense = true;
      };
    };
    arguments = {
      inherit
        pkgs-stable
        username
        terminal
        wallpaper
        system
        locale
        timezone
        hostname
        kbdLayout
        ;
    };
  in {
    nixosConfigurations.zaros = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = (arguments // {inherit inputs;}) // inputs;
      modules = [
        ./hosts/zaros/configuration.nix
        inputs.home-manager.nixosModules.default
      ];
    };
  };
}
