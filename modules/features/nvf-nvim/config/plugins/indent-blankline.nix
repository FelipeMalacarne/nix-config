{
  vim.visuals.indent-blankline = {
    enable = true;
    setupOpts = {
      indent.char = "│";
      scope.enabled = false;
      exclude.filetypes = [
        "help"
        "lazy"
        "neo-tree"
        "Trouble"
        "toggleterm"
      ];
    };
  };
}
