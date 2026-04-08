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
    ../../modules/nixos/tailscale.nix
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
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "bak"; 
  home-manager.users.felipe = {
    imports = [
      ../../modules/home/common
      ../../modules/home/desktop/hyprland
      ../../modules/home/desktop/terminal.nix
      ../../modules/home/desktop/noctalia.nix
      ../../modules/home/desktop/wallpaper.nix
      ../../modules/home/desktop/firefox.nix
      ../../modules/home/desktop/steam.nix
      ../../modules/home/desktop/dolphin.nix
    ];

    desktop.terminal.name = "ghostty";

    home = {
      username = "felipe";
      homeDirectory = "/home/felipe";
      packages = with pkgs; [
        fastfetch
        bitwarden-desktop
      ];
    };
  };

  programs.firefox.enable = true;

  system.stateVersion = "24.11";
}
