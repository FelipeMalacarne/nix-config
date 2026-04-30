{ inputs, ... }:
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
  # so `nix run nixpkgs#foo` uses the same version as the system
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
