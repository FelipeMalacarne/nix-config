{ lib, ... }:
let
  module = {
    options.my.user = lib.mkOption {
      type = lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
            default = "felipe";
            description = "User account name used by system and home-manager modules.";
          };
          fullName = lib.mkOption {
            type = lib.types.str;
            default = "FelipeMalacarne";
            description = "User's full name.";
          };
          email = lib.mkOption {
            type = lib.types.str;
            default = "felipemalacarne012@gmail.com";
            description = "User's email address.";
          };
          homeDirectory = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional explicit home directory; otherwise the platform default is used.";
          };
        };
      };
      description = "Cross-platform identity contract.";
    };
  };
in
{
  flake.nixosModules.identity = module;
  flake.darwinModules.identity = module;
  flake.homeModules.identity = module;
}
