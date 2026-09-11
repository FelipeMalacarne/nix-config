require("which-key").setup({})

keybind("n", "<leader>?", function()
	require("which-key").show({ global = false })
end, "Show which-key")
