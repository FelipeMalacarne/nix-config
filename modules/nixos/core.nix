# modules/nixos/core.nix
{ inputs, ... }:
{
  # Locale and timezone
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Sao_Paulo";

  services.xserver.xkb = {
    layout = "us";
    variant = "intl";
  };

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  # Pin the flake registry to the same nixpkgs used by this flake
  # so `nix run nixpkgs#foo` uses the same version as the system
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  nixpkgs.config.allowUnfree = true;
}
