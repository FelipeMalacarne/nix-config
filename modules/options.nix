# modules/options.nix
#
# Shared option declarations used across feature modules.
{ lib, ... }:
{
  options.my.user.name = lib.mkOption {
    type = lib.types.str;
    default = "felipe";
    description = "User account name used by system and home-manager modules.";
  };
}
