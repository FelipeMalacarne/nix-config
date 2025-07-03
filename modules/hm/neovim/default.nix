{ pkgs, ... }:

let
  treesitterWithGrammars = (pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
    p.bash
    p.comment
    p.css
    p.dockerfile
    p.fish
    p.gitattributes
    p.gitignore
    p.go
    p.gomod
    p.gowork
    p.hcl
    p.javascript
    p.jq
    p.json5
    p.json
    p.lua
    p.make
    p.markdown
    p.nix
    p.python
    p.rust
    p.toml
    p.typescript
    p.yaml
  ]));
in {
  home.packages = with pkgs; [
    # Essentials
    ripgrep
    fd
    lazygit
    gcc # Required for some plugins if not using Nix parsers

    # Linters, Formatters, and LSPs
    alejandra
    black
    gopls
    lua-language-server # Removed duplicate
    nixd
    nixfmt
    ruff
    rust-analyzer-unwrapped
    tailwindcss-language-server
    typescript-language-server # Replaced vtsls for broader support
    vscode-langservers-extracted # For JSON, CSS, HTML LSPs
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    package = pkgs.neovim-unwrapped;
    withNodeJs = true;

    plugins = [ pkgs.vimPlugins.nvim-treesitter treesitterWithGrammars ];
  };

  home.file.".config/nvim/" = {
    source = ./nvim;
    recursive = true;
  };
}
