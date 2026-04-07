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
    ../../modules/nixos/steam.nix
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

  # Home Manager wiring
  home-manager.useGlobalPkgs = true; # share nixpkgs with system — better cache hits
  home-manager.useUserPackages = true; # install user packages into system profile
  home-manager.backupFileExtension = "bak"; # back up conflicting files instead of failing
  home-manager.users.felipe = {
    imports = [
      ../../modules/home/common
      ../../modules/home/desktop/hyprland
      ../../modules/home/desktop/alacritty.nix
      ../../modules/home/desktop/noctalia.nix
      ../../modules/home/desktop/wallpaper.nix
      ../../modules/home/desktop/firefox.nix
      ../../modules/home/desktop/steam.nix
    ];
    home.username = "felipe";
    home.homeDirectory = "/home/felipe";
  };

  programs.firefox.enable = true;

  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/8701a071-fed6-475b-a14c-40ef8e46e76a";
    fsType = "ext4";
    options = [
      "defaults"
      "nofail"
    ];
  };

  system.stateVersion = "24.11";
}
