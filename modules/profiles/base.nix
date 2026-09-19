{ config, ... }:
let
  registry = config.flake.modules;
in
{
  flake.modules.nixos.base = {
    imports = [
      registry.nixos.infrastructure
      registry.nixos.identity
      registry.nixos.core
      registry.nixos.theming
      registry.nixos.zsh
      registry.nixos.ssh
      registry.nixos.optional-features
    ];
  };

  flake.modules.darwin.base = {
    imports = [
      registry.darwin.infrastructure
      registry.darwin.identity
      registry.darwin.core
      registry.darwin.theming
      registry.darwin.zsh
      registry.darwin.ssh
    ];
  };

  flake.modules.homeManager.base = {
    imports = with registry.homeManager; [
      infrastructure
      sops
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
