{ config, ... }:
let
  registry = config.flake.modules;
  # Core settings shared by NixOS and nix-darwin; each platform file adds the
  # rest of `core`, including the Home Manager platform module itself.
  module =
    { config, lib, ... }:
    let
      user = config.my.user.name;
    in
    {
      nixpkgs.config.allowUnfree = true;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";

        users.${user} = {
          imports = [ registry.homeManager.identity ];
          my.user = config.my.user;
          home = {
            username = user;
            homeDirectory = lib.mkDefault config.users.users.${user}.home;
            stateVersion = lib.mkDefault "24.11";
          };
        };
      };
    };
in
{
  flake.modules.nixos.core = module;
  flake.modules.darwin.core = module;
}
