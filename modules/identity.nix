{ lib, ... }:
let
  module = {
    options.my.user.name = lib.mkOption {
      type = lib.types.str;
      default = "felipe";
      description = "User account name used by system and home-manager modules.";
    };
  };
in
{
  flake.nixosModules.identity = module;
  flake.darwinModules.identity = module;
}
