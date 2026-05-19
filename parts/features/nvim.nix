{ inputs, ... }:
{
  flake.nixosModules.nvim = { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user} = { config, ... }: {
        home.packages = [
          (inputs.nvim-config.lib.mkPackage pkgs config.colorScheme.palette)
        ];
      };
    };
}
