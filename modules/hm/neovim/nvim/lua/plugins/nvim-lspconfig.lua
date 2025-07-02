return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
        nixd = {
            nixpkgs = {
                expr = " import <nixpkgs> { }"
            },
            formatting = {
                command = { "nixfmt" },
            },
        },
    },
    setup = {
    },
  },
}
