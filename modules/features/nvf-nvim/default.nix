{ inputs, ... }:
let
  module =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user} =
        { lib, pkgs, ... }:
        {
          imports = [ inputs.nvf.homeManagerModules.default ];

          home.packages = with pkgs; [
            texlive.combined.scheme-full
            zathura
          ];

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
