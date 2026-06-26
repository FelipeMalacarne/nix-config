require("snacks").setup({
	animate = { enabled = false },
	bigfile = { enabled = true },
	bufdelete = { enabled = true },
	dim = { enabled = true },
	indent = { enabled = true },
	input = { enabled = true },
	notifier = { enabled = true },
	picker = {
		enabled = true,
		ui_select = true,
	},
	scope = { enabled = true },
	scroll = { enabled = false },
	statuscolumn = { enabled = true },
	terminal = { enabled = true },
	words = { enabled = true },
	zen = { enabled = true },
	-- dashboard = {
	--   enabled = true,
	-- },
})

if Snacks.statusline then
	vim.o.statusline = "%{v:lua.Snacks.statusline()}"
end
