{ inputs, lib, ... }:
{
  imports = [
    inputs.flake-parts.flakeModules.modules
  ];

  options.flake.darwinModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
    default = { };
  };

  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
    default = { };
  };
}
