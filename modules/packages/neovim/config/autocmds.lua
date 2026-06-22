local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Restore cursor position when reopening a file
autocmd("BufReadPost", {
	group = augroup("restore_cursor", { clear = true }),
	callback = function(ev)
		local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
		local line_count = vim.api.nvim_buf_line_count(ev.buf)
		if mark[1] > 0 and mark[1] <= line_count then
			vim.api.nvim_win_set_cursor(0, mark)
		end
	end,
})

-- Disable auto-comment continuation on new lines
autocmd("FileType", {
	group = augroup("no_auto_comment", { clear = true }),
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- Highlight text briefly after yanking
autocmd("TextYankPost", {
	group = augroup("yank_highlight", { clear = true }),
	callback = function()
		vim.highlight.on_yank({ higroup = "Visual", timeout = 150 })
	end,
})

-- When nvim is called with a directory argument (e.g. nvim .), cd into it
-- and show the dashboard instead of an empty/broken buffer
autocmd("VimEnter", {
	group = augroup("open_dir", { clear = true }),
	once = true,
	callback = function()
		local arg = vim.fn.argv(0)
		if arg and arg ~= "" and vim.fn.isdirectory(arg) == 1 then
			vim.cmd("cd " .. vim.fn.fnameescape(arg))
			vim.cmd("bwipeout")
		end
	end,
})

-- Warn if lazygit / lazydocker are not installed
autocmd("VimEnter", {
	group = augroup("check_lazy_tools", { clear = true }),
	once = true,
	callback = function()
		if vim.fn.executable("lazygit") == 0 then
			vim.notify("lazygit not found in PATH — install it via your package manager", vim.log.levels.WARN)
		end
		if vim.fn.executable("lazydocker") == 0 then
			vim.notify("lazydocker not found in PATH — install it via your package manager", vim.log.levels.WARN)
		end
	end,
})

-- Resize splits when the terminal window is resized
autocmd("VimResized", {
	group = augroup("resize_splits", { clear = true }),
	callback = function()
		vim.cmd("tabdo wincmd =")
	end,
})
