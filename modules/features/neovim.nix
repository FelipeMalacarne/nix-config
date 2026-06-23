{ self, ... }:
let
  module =
    { pkgs, config, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user} = {
        home.packages = [
          self.packages.${pkgs.stdenv.hostPlatform.system}.neovim
        ];
      };
    };
in
{
  flake.nixosModules.neovim = module;
  flake.darwinModules.neovim = module;
}
