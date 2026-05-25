{ lib, ... }:
let
  inherit (lib.generators) mkLuaInline;
in
{
  vim.mini = {
    ai.enable = true;
    surround = {
      enable = true;
      setupOpts.mappings = {
        add = "gsa";
        delete = "gsd";
        find = "gsf";
        find_left = "gsF";
        highlight = "gsh";
        replace = "gsr";
        update_n_lines = "gsn";
      };
    };
    comment = {
      enable = true;
      setupOpts.options.custom_commentstring = mkLuaInline ''
        function()
          return require("ts_context_commentstring.internal").calculate_commentstring()
            or vim.bo.commentstring
        end
      '';
    };
    jump2d.enable = true;
  };
}
