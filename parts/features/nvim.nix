{ inputs, ... }:
let
  module = { config, pkgs, ... }:
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
in
{
  flake.nixosModules.nvim = module;
  flake.darwinModules.nvim = module;
}
