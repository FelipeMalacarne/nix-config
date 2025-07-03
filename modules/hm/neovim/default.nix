{ pkgs, ... }:
let

  # treesitterWithGrammars = (pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
  #   p.bash
  #   p.comment
  #   p.css
  #   p.dockerfile
  #   p.fish
  #   p.gitattributes
  #   p.gitignore
  #   p.go
  #   p.gomod
  #   p.gowork
  #   p.hcl
  #   p.javascript
  #   p.jq
  #   p.json5
  #   p.json
  #   p.lua
  #   p.make
  #   p.markdown
  #   p.nix
  #   p.python
  #   p.rust
  #   p.toml
  #   p.typescript
  #   p.yaml
  # ]));

  treesitter-parsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    # paths = treesitterWithGrammars.dependencies;
  };
in {
  home.packages = with pkgs; [
    ripgrep
    fd
    lazygit
    libgcc
    lua-language-server
    rust-analyzer-unwrapped
    black
    gcc
    gopls
    ruff
    nixd
    lua-language-server
    tailwindcss-language-server
    vscode-langservers-extracted
    vtsls
    nixfmt
    alejandra
  ];

  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    vimAlias = true;
    coc.enable = false;
    withNodeJs = true;
    defaultEditor = true;

    # plugins = [ treesitterWithGrammars ];

    plugins = with pkgs.vimPlugins; [
      nvim-treesitter.withAllGrammars # Or specify grammars as you did before
    ];

  };

  home.file."./.config/nvim/" = {
    source = ./nvim;
    recursive = true;
  };

  # home.file."./.local/share/nvim/nix/nvim-treesitter/" = {
  #   recursive = true;
  #   source = treesitterWithGrammars;
  # };
}
