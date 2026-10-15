{ config, self, ... }:
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
  flake.modules.homeManager.development = { lib, pkgs, ... }: {
    imports = with registry.homeManager; [
      neovim
      programming
      k8s
    ];
    my.neovim.package = lib.mkDefault self.packages.${pkgs.stdenv.hostPlatform.system}.neovim-full;
  };
}
