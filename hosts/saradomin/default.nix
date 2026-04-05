# hosts/saradomin/default.nix
{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/network.nix
    ../../modules/nixos/desktop.nix # temporary — remove after desktop validation
  ];

  networking.hostName = "saradomin";

  # User account
  programs.zsh.enable = true;
  users.users.felipe = {
    isNormalUser = true;
    shell = pkgs.zsh;
    initialPassword = "nixos"; # change after install
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
    ];
  };

  # Home Manager wiring
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.felipe = {
    imports = [
      ../../modules/home/common
      ../../modules/home/desktop/hyprland
      ../../modules/home/desktop/ghostty.nix
      ../../modules/home/desktop/noctalia.nix
    ];
    home.username = "felipe";
    home.homeDirectory = "/home/felipe";
  };

  system.stateVersion = "24.11";
}
