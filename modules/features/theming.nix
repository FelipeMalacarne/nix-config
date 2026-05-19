# modules/features/theming.nix
#
# Integrates nix-colors into home-manager and exposes myConfig.colorScheme
# as a NixOS-level option so hosts can set the active color scheme once.
# All other features that use config.colorScheme.palette depend on this.
{
  config,
  inputs,
  lib,
  ...
}:
let
  user = config.my.user.name;
in
{
  options.myConfig.colorScheme = lib.mkOption {
    type = lib.types.str;
    default = "catppuccin-mocha";
    description = "nix-colors scheme name to use system-wide.";
  };

  config.home-manager.users.${user} = {
    imports = [ inputs.nix-colors.homeManagerModules.default ];
    colorScheme = inputs.nix-colors.colorSchemes.${config.myConfig.colorScheme};
  };
}
