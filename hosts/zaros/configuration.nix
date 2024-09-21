# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ 
      inputs.home-manager.nixosModules.default
      ./hardware-configuration.nix
      ./../../modules/nixos/nvidia.nix
      ./../../modules/nixos/gnome.nix
      ./../../modules/nixos/i18n.nix
      ./../../modules/nixos/fonts.nix
      ./../../modules/nixos/bootloader.nix
      ./../../modules/nixos/networking.nix
      ./../../modules/nixos/services.nix
      ./../../modules/nixos/sound.nix
      ./../../modules/hyprland.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Define a user account. Don't forget to set a password with ‘passwd’.

  users.users.felipemalacarne = {
    isNormalUser = true;
    description = "felipemalacarne";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
	    vim
    ];
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = {
      "felipemalacarne" = import ./home.nix;
    };
  };

  # Install firefox.
  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    lf
    wget
    git
    tmux
    xclip
    lazygit
    htop
    btop
    vscode
  ];

  programs.ssh.startAgent = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
