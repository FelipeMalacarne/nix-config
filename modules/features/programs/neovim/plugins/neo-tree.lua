-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("neo-tree").setup({
	filesystem = {
		follow_current_file = true,
	},

	window = {
		position = "float",
		width = 35,
		mappings = {
			["<space>"] = "none",
			["l"] = "open",
			["h"] = "close_node",
		},
	},
})

keybind("n", "<leader>e", "<cmd>Neotree toggle<cr>", "Toggle file explorer")
keybind("n", "<leader>E", "<cmd>Neotree toggle dir=%:p:h<cr>", "Toggle file explorer (current file's directory)")
