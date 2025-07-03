return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    -- On NixOS, this should be empty, as Nix manages the parsers.
    ensure_installed = {},

    -- Or you can have auto_install = false
    auto_install = false,

    highlight = {
      enable = true,
    },
  },
}
