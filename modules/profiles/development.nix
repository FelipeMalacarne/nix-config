{ config, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.nixos.development = { config, ... }: {
    imports = [
      registry.nixos.programming
      registry.nixos.k8s
    ];
    home-manager.users.${config.my.user.name}.imports = [ registry.homeManager.development ];
  };
  flake.modules.darwin.development = { config, ... }: {
    imports = [
      registry.darwin.programming
      registry.darwin.k8s
    ];
    home-manager.users.${config.my.user.name}.imports = [ registry.homeManager.development ];
  };
  flake.modules.homeManager.development = { lib, ... }: {
    imports = with registry.homeManager; [
      neovim
      programming
      k8s
    ];
    my.neovim.variant = lib.mkDefault "full";
  };
}
