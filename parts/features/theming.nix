{ inputs, ... }:
{
  flake.nixosModules.theming = { config, lib, ... }:
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
    };
}
