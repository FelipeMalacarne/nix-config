{ lib, pkgs, ... }:
let
  inherit (lib.nvim.dag) entryAnywhere;
in
{
  vim = {
    startPlugins = [ pkgs.vimPlugins.dressing-nvim ];

    pluginRC.dressing = entryAnywhere ''
      require("dressing").setup({})
    '';
  };
}
