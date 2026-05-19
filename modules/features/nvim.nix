{ inputs, ... }:
let
  module = { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user} = { config, lib, ... }:
        let
          c = config.lib.stylix.colors;
          palette = lib.filterAttrs (n: _: builtins.match "base[0-9A-Fa-f]{2}" n != null) c;
        in
        {
          home.packages = [
            (inputs.nvim-config.lib.mkPackage pkgs palette)
          ];
        };
    };
in
{
  flake.nixosModules.nvim = module;
  flake.darwinModules.nvim = module;
}
