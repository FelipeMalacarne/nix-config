{ self, pkgs, ... }:
let

  selfpkgs = self.packages.${pkgs.stdenv.hostPlatform.system};
  module =
    { pkgs, config, ... }:
    {
      programs.neovim = {
        enable = true;
        package = selfpkgs.neovim;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };
    };
in
{
  flake.nixosModules.neovim = module;
  flake.darwinModules.neovim = module;
}
