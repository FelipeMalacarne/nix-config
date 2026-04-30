# modules/features/core.nix
#
# Core system config every NixOS host needs: locale, timezone, nix settings,
# boot, home-manager base wiring, and primary user account setup.
{
  inputs,
  config,
  lib,
  ...
}:
let
  user = config.myConfig.primaryUser;
in
{
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Sao_Paulo";

  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;

  # Pin the flake registry to the same nixpkgs used by this flake
  # so `nix run nixpkgs#foo` uses the same version as the system.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Home-manager base wiring
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "bak";

  # Primary user account
  users.users.${user} = {
    isNormalUser = true;
    initialPassword = "nixos";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };

  home-manager.users.${user} = {
    home = {
      username = user;
      homeDirectory = lib.mkDefault "/home/${user}";
      stateVersion = lib.mkDefault "24.11";
    };
  };
}
