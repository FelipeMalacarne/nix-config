{ inputs, ... }:
let
  module =
    { config, pkgs, ... }:
    let
      user = config.my.user.name;
    in
    {
      home-manager.users.${user} =
        { lib, ... }:
        let
          nvfConfig = file: import file { inherit inputs pkgs lib; };
        in
        {
          imports = [ inputs.nvf.homeManagerModules.default ];

          programs.nvf = {
            enable = true;
            settings = lib.mkMerge [
              (nvfConfig ./_nvim/core.nix)
              (nvfConfig ./_nvim/languages.nix)
              (nvfConfig ./_nvim/plugins.nix)
              (nvfConfig ./_nvim/formatting.nix)
              (nvfConfig ./_nvim/keymaps.nix)
              (nvfConfig ./_nvim/lua.nix)
            ];
          };
        };
    };
in
{
  flake.nixosModules.nvim = module;
  flake.darwinModules.nvim = module;
}
