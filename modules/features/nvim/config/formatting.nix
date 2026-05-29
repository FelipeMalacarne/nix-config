{ pkgs, lib, ... }:
{
  vim = {
    formatter.conform-nvim = {
      enable = true;
      setupOpts = {
        formatters_by_ft = {
          go = [
            "goimports"
            "gofmt"
          ];
          php = [ "pint" ];
          blade = [ "blade-formatter" ];
          html = [ "prettier" ];
          yaml = [ "prettier" ];
          markdown = [ "prettier" ];
        };
        formatters = {
          goimports.command = lib.getExe' pkgs.gotools "goimports";
          gofmt.command = "${pkgs.go}/bin/gofmt";
          blade-formatter.command = lib.getExe pkgs.blade-formatter;
          prettier.command = lib.getExe pkgs.prettier;
        };
        format_on_save = null;
        format_after_save = null;
      };
    };

    diagnostics.nvim-lint = {
      enable = true;
      linters_by_ft = {
        # javascript = [ "eslint_d" ];
        # javascriptreact = [ "eslint_d" ];
        # typescriptreact = [ "eslint_d" ];
      };
    };
  };
}
