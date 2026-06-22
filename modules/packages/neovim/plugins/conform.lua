require("conform").setup({
	formatters_by_ft = {
		["*"] = { "trim_whitespace" },

		lua = { "stylua" },
		php = { "pint" },
		javascript = { "prettierd" },
		typescript = { "prettierd" },
		javascriptreact = { "prettierd" },
		typescriptreact = { "prettierd" },
		json = { "prettierd" },
		yaml = { "prettierd" },
		markdown = { "prettierd" },
		css = { "prettierd" },
		scss = { "prettierd" },
		html = { "prettierd" },
		sh = { "shfmt" },
		nix = { "nixfmt" },
	},

	format_on_save = false,
})

keybind("n", "<leader>cf", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, "Format buffer (conform)")
