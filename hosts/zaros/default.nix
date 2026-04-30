# hosts/zaros/default.nix
{ pkgs, config, ... }:
let
  user = config.myConfig.primaryUser;
in
{
  imports = [
    ./hardware.nix
    ../../modules/options.nix
    ../../modules/nixos/network.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/kdeconnect.nix
    ../../modules/nixos/tailscale.nix
    ../../modules/features/core.nix
    ../../modules/features/zsh.nix
    ../../modules/features/fonts.nix
    ../../modules/features/gaming.nix
    ../../modules/features/nvidia.nix
    ../../modules/features/hyprland
    ../../modules/features/noctalia.nix
    ../../modules/features/alacritty.nix
  ];

  networking.hostName = "zaros";

  security.pki.certificateFiles = [
    ../../certs/saradomin-internal-ca.crt
  ];

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
    };
  };

  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
  };

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
  };

  services.flatpak.enable = true;

  users.users.${user} = {
    isNormalUser = true;
    initialPassword = "nixos";
    openssh.authorizedKeys.keyFiles = [
      ../../keys/zaros.pub
      ../../keys/bitbaut.pub
    ];
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "docker"
    ];
  };

  # Home Manager wiring
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "bak";
  home-manager.users.felipe = {
    imports = [
      ../../modules/home/common
      ../../modules/home/desktop/idle.nix
      ../../modules/home/desktop/wallpaper.nix
      ../../modules/home/desktop/firefox.nix
      ../../modules/home/desktop/dolphin.nix
      ../../modules/home/desktop/yazi.nix
    ];

    desktop.colorScheme = "catppuccin-mocha";

    home = {
      username = "felipe";
      homeDirectory = "/home/felipe";
      packages = with pkgs; [
        fastfetch
        bitwarden-desktop
        opencode
        libreoffice-fresh
        hunspell
        hunspellDicts.pt_BR
        hunspellDicts.en_US
        zathura
        dbeaver-bin
        mongodb-compass
      ];
    };
  };

  programs.firefox.enable = true;

  system.stateVersion = "24.11";
}
