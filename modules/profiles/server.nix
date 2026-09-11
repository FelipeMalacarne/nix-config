{ config, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.nixos.server = { config, ... }: {
    imports = [
      registry.nixos.base
      registry.nixos.sops
    ];
    home-manager.users.${config.my.user.name}.imports = [ registry.homeManager.linux-base ];
  };
}
