local opt = vim.opt

-- UI
opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.wrap = false
opt.scrolloff = 10
opt.sidescrolloff = 10
opt.signcolumn = "yes"
opt.colorcolumn = "100"
opt.showmatch = true
opt.showmode = false
opt.pumheight = 10
opt.pumblend = 10
opt.winblend = 0
opt.conceallevel = 0
opt.concealcursor = ""
opt.fillchars = { eob = " " }

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

-- Completion
opt.completeopt = "menuone,noinsert,noselect"

-- Files / undo
local undodir = vim.fn.expand("~/.vim/undodir")
if vim.fn.isdirectory(undodir) == 0 then
	vim.fn.mkdir(undodir, "p")
end
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undodir = undodir
opt.autoread = true
opt.autowrite = false

-- Timing
opt.updatetime = 300
opt.timeoutlen = 500
opt.ttimeoutlen = 0

-- Behaviour
opt.hidden = true
opt.errorbells = false
opt.backspace = "indent,eol,start"
opt.autochdir = false
opt.iskeyword:append("-")
opt.path:append("**")
opt.selection = "inclusive"
opt.mouse = "a"
opt.clipboard:append("unnamedplus")
opt.modifiable = true
opt.encoding = "UTF-8"

opt.guicursor =
	"n-v-c:block,i-ci-ve:block,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"

-- Folding (treesitter-based)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99

-- Splits
opt.splitbelow = true
opt.splitright = true

-- Wildmenu / misc
opt.wildmenu = true
opt.wildmode = "longest:full,full"
opt.diffopt:append("linematch:60")
opt.redrawtime = 10000
opt.maxmempattern = 20000
