let
  module = { config, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user} = {
        programs.btop = {
          enable = true;
          settings = {
            theme_background = false;
            update_ms = 2000;
            rounded_corners = true;
          };
        };
      };
    };
in
{
  flake.nixosModules.btop = module;
  flake.darwinModules.btop = module;
}
