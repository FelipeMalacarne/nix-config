{
  flake.nixosModules.bitwarden = { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user}.home.packages = [ pkgs.bitwarden-desktop ];
    };
}
