{ lib, pkgs, ... }:
let
  inherit (lib.nvim.dag) entryBefore;
in
{
  vim = {
    startPlugins = [ pkgs.vimPlugins.nvim-ts-context-commentstring ];

    pluginRC.ts-context-commentstring = entryBefore [ "mini-comment" ] ''
      require("ts_context_commentstring").setup({ enable_autocmd = false })
    '';
  };
}
