{ pkgs, ...}:
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
    p.react
    p.yaml
  ]));

  treesitter-parsers = pkgs.symlinkJoin {
    name = "treesitter-parsers";
    paths = treesitterWithGrammars.dependencies;
  };
in
{
	home.packages = with pkgs; [
	    ripgrep
	    fd
	    lua-language-server
	    rust-analyzer-unwrapped
	    black
	  ];

	  programs.neovim = {
	    enable = true;
	    package = pkgs.neovim-unwrapped;
	    vimAlias = true;
	    coc.enable = false;
	    withNodeJs = true;

	    plugins = [
	      treesitterWithGrammars
	    ];
	  };


}
