{ ... }:
let
  module = {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "bak";
  };
in
{
  flake.modules.nixos.home-manager-policy = module;
  flake.modules.darwin.home-manager-policy = module;
}
