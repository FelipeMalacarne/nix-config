{ config, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.nixos.server = {
    imports = [ registry.nixos.base ];
  };
}
