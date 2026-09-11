{ config, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.nixos.development = {
    imports = [
      registry.nixos.programming
      registry.nixos.k8s
    ];
  };
  flake.modules.darwin.development = {
    imports = [
      registry.darwin.programming
      registry.darwin.k8s
    ];
  };
  flake.modules.homeManager.development = {
    imports = with registry.homeManager; [
      programming
      opencode
      k8s
    ];
  };
}
