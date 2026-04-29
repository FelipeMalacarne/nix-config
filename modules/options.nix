# modules/options.nix
#
# Shared option declarations used across feature modules.
{ lib, ... }:
{
  options.myConfig.primaryUser = lib.mkOption {
    type = lib.types.str;
    default = "felipe";
    description = "Primary user account name. Used by feature modules to wire home-manager.";
  };
}
