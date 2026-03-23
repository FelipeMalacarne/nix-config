# hosts/zaros/default.nix
{ inputs, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ../../modules/nixos/core.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/network.nix
    ../../modules/nixos/desktop.nix
  ];

  # User account
  users.users.felipe = {
    isNormalUser = true;
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

  # VM variant — LLVMPipe software rendering for config iteration on Arch
  # Run with: nixos-rebuild build-vm --flake .#zaros && ./result/bin/run-zaros-vm
  virtualisation.vmVariant = {
    virtualisation.diskSize = 8192; # MiB — default 512 MiB too small for Hyprland + Noctalia
    virtualisation.qemu.options = [
      "-vga none"
      "-device virtio-gpu-pci" # enables LLVMPipe OpenGL — required for Hyprland
      "-m 4G"
      "-smp 2"
    ];
  };

  system.stateVersion = "24.11";
}
