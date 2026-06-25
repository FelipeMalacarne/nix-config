require("telescope").setup({
	defaults = {
		prompt_prefix = "  ",
		selection_caret = " ",
		path_display = { "truncate" },
		sorting_strategy = "ascending",
		layout_config = {
			horizontal = { prompt_position = "top", preview_width = 0.55 },
			vertical = { mirror = false },
			width = 0.87,
			height = 0.80,
		},
		mappings = {
			i = {
				["<C-j>"] = "move_selection_next",
				["<C-k>"] = "move_selection_previous",
				["<C-q>"] = "send_to_qflist",
				["<esc>"] = "close",
			},
		},
	},
})

keybind("n", "<leader>ff", "<cmd>Telescope find_files<cr>", "Find files")
keybind("n", "<leader><leader>", "<cmd>Telescope find_files<cr>", "Find files")
keybind("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", "Live grep")
keybind("n", "<leader>fb", "<cmd>Telescope buffers<cr>", "Buffers")
keybind("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", "Help tags")
keybind("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", "Recent files")
keybind("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", "Document symbols")
keybind("n", "<leader>fw", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", "Workspace symbols")
keybind("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>", "Diagnostics")
keybind("n", "<leader>/", "<cmd>Telescope current_buffer_fuzzy_find<cr>", "Fuzzy find in buffer")

pcall(require("telescope").load_extension, "fzf")
