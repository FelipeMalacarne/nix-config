{ inputs, ... }:
let
  module =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user} =
        { lib, ... }:
        {
          imports = [ inputs.nvf.homeManagerModules.default ];

          programs.nvf = {
            enable = true;
            settings = {
              imports = [ ./config ];
            };
          };
        };
    };
in
{
  flake.nixosModules.nvim = module;
  flake.darwinModules.nvim = module;
}
