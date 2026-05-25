{
  pkgs,
  lib,
  ...
}:
let
  inherit (lib.generators) mkLuaInline;
in
{
  vim = {
    viAlias = false;
    vimAlias = true;
    enableLuaLoader = true;

    globals = {
      mapleader = " ";
      maplocalleader = " ";
      loaded_netrw = 1;
      loaded_netrwPlugin = 1;
    };

    # Most language tools come from NVF language modules. These remain because
    # custom terminal keymaps use them directly, and gopls' root detection calls `go`.
    extraPackages = with pkgs; [
      go
      lazygit
      lazydocker
      lazysql
    ];

    lineNumberMode = "relNumber";
    searchCase = "smart";
    preventJunkFiles = true;
    undoFile = {
      enable = true;
      path = mkLuaInline ''vim.fn.expand("~/.vim/undodir")'';
    };

    options = {
      termguicolors = true;
      cursorline = true;
      wrap = false;
      scrolloff = 10;
      sidescrolloff = 10;
      signcolumn = "yes";
      colorcolumn = "100";
      showmatch = true;
      showmode = false;
      pumheight = 10;
      pumblend = 10;
      winblend = 0;
      conceallevel = 0;
      concealcursor = "";
      fillchars.eob = " ";
      tabstop = 2;
      shiftwidth = 2;
      softtabstop = 2;
      expandtab = true;
      smartindent = true;
      autoindent = true;
      hlsearch = true;
      incsearch = true;
      completeopt = "menuone,noinsert,noselect";
      backup = false;
      writebackup = false;
      swapfile = false;
      autoread = true;
      autowrite = false;
      updatetime = 300;
      timeoutlen = 500;
      ttimeoutlen = 0;
      hidden = true;
      errorbells = false;
      backspace = "indent,eol,start";
      autochdir = false;
      selection = "inclusive";
      mouse = "a";
      modifiable = true;
      encoding = "UTF-8";
      guicursor = "n-v-c:block,i-ci-ve:block,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175";
      foldmethod = "expr";
      foldexpr = "v:lua.vim.treesitter.foldexpr()";
      foldlevel = 99;
      splitbelow = true;
      splitright = true;
      wildmenu = true;
      wildmode = "longest:full,full";
      redrawtime = 10000;
      maxmempattern = 20000;
    };
  };
}
