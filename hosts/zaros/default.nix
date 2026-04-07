# hosts/zaros/default.nix
{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/network.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/gpu/nvidia.nix
    ../../modules/nixos/desktop.nix
  ];

  networking.hostName = "zaros";

  programs.zsh.enable = true; 
  users.users.felipe = {
    isNormalUser = true;
    shell = pkgs.zsh; 
    initialPassword = "nixos"; 
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
    ];
  };

  home-manager.useGlobalPkgs = true; 
  home-manager.useUserPackages = true;
  home-manager.users.felipe = {
    imports = [
      ../../modules/home/common
      ../../modules/home/desktop/hyprland
      ../../modules/home/desktop/alacritty.nix
      ../../modules/home/desktop/noctalia.nix
    ];
    home.username = "felipe";
    home.homeDirectory = "/home/felipe";
  };

  system.stateVersion = "24.11";
}
