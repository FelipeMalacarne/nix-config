# modules/features/darwin/core.nix
#
# Darwin-specific system core — nix-darwin equivalent of features/core.nix.
# Handles nix settings, user account, home-manager wiring, and macOS defaults.
{ config, lib, ... }:
let
  user = config.myConfig.primaryUser;
in
{
  nix.settings.experimental-features = "nix-command flakes";
  nixpkgs.config.allowUnfree = true;

  system.primaryUser = user;
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;

  users.users.${user} = {
    name = user;
    home = "/Users/${user}";
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "bak";

  home-manager.users.${user} = {
    home.username = user;
    home.homeDirectory = lib.mkDefault "/Users/${user}";
    home.stateVersion = lib.mkDefault "24.11";
  };
}
