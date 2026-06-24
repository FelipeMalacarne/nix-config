local M = {}

function M.open_win(executable, opts)
	opts = opts or {}
	local state = { buf = nil, win = nil }

	local function close()
		if state.win and vim.api.nvim_win_is_valid(state.win) then
			vim.api.nvim_win_close(state.win, true)
		end
		state.buf = nil
		state.win = nil
	end

	local function toggle()
		if state.win and vim.api.nvim_win_is_valid(state.win) then
			close()
			return
		end

		local width = math.floor(vim.o.columns * 0.9)
		local height = math.floor(vim.o.lines * 0.9)
		state.buf = vim.api.nvim_create_buf(false, true)
		state.win = vim.api.nvim_open_win(state.buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = math.floor((vim.o.lines - height) / 2),
			col = math.floor((vim.o.columns - width) / 2),
			style = "minimal",
			border = "none",
		})

		vim.fn.jobstart(executable, {
			term = true,
			on_exit = function()
				close()
			end,
		})

		if opts.terminal then
			vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = state.buf, desc = "Exit terminal insert mode" })
		end
		vim.cmd("startinsert")
	end

	return toggle
end

return M
