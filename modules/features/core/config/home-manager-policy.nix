{ ... }:
let
  module = {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "bak";
  };
in
{
  flake.nixosModules.home-manager-policy = module;
  flake.darwinModules.home-manager-policy = module;
}
