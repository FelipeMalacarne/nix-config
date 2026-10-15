{ config, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.nixos.base = { config, ... }: {
    imports = [
      registry.nixos.infrastructure
      registry.nixos.identity
      registry.nixos.core
      registry.nixos.theming
      registry.nixos.zsh
      registry.nixos.ssh
    ];
    home-manager.users.${config.my.user.name}.imports = [ registry.homeManager.linux-base ];
  };

  flake.modules.darwin.base = { config, ... }: {
    imports = [
      registry.darwin.infrastructure
      registry.darwin.identity
      registry.darwin.core
      registry.darwin.theming
      registry.darwin.zsh
      registry.darwin.ssh
    ];
    home-manager.users.${config.my.user.name}.imports = [ registry.homeManager.base ];
  };

  flake.modules.homeManager.base = {
    imports = with registry.homeManager; [
      infrastructure
      zsh
      git
      ssh
      neovim
      cli
      btop
    ];
  };

  flake.modules.homeManager.linux-base = {
    imports = with registry.homeManager; [
      base
      yazi
    ];
  };
}
