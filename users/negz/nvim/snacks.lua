local snacks = require('snacks')

snacks.setup {
	bufdelete = { enabled = true },
	input = { enabled = true },
	notifier = { enabled = true },
	image = { enabled = true },
	indent = {
		enabled = true,
		animate = { enabled = false },
		indent = {
			hl = "IndentBlanklineChar"
		},
		scope = {
			underline = false,
			hl = "IndentBlanklineChar"
		}
	},
	picker = {
		enabled = true,
		layout = { preset = "telescope" },
		ui_select = true,
		matcher = {
			cwd_bonus = true,
			frecency = true,
			history_bonus = true,
		},
		sources = {
			-- This is a tree, so it works best unflipped.
			lsp_symbols = { layout = "default" },
			explorer = {
				layout = {
					preview = false,
					layout = {
						position = "right",
						backdrop = false,
						width = 35,
						min_width = 35,
						height = 0,
						border = "none",
						box = "vertical",
						{ win = "list", border = "none" },
						{
							win = "input",
							height = 1,
							border = "rounded",
							title = "{title} {live} {flags}",
							title_pos = "center",
						},
					},
				},
				win = {
					input = { keys = { ["<Esc>"] = false } },
					list = { keys = { ["<Esc>"] = false } },
				},

			},
		},
		icons = {
			tree = {
				vertical = "│ ",
				middle   = "│ ",
				last     = "└╴",
			},
			diagnostics = {
				Error = ' ',
				Warn = ' ',
				Hint = '󰌶 ',
				Info = ' '
			},
		},
	},
	explorer = {
		replace_netrw = true
	},
	quickfile = { enabled = true },
}



-- Open explorer when opening vim.
vim.api.nvim_create_autocmd("UiEnter", {
	callback = function()
		-- Calling snacks.picker.explorer() or snacks.explorer().open() actually
		-- toggles the explorer. The explorer will already be open if we open a
		-- directory due to the netrw hijack, so calling open would actually
		-- close it. So here we only open it if it's not already open.
		local explorer_pickers = snacks.picker.get({ source = "explorer" })
		if #explorer_pickers > 0 then
			return
		end

		-- TODO(negz): Don't focus if we opened a file.
		snacks.picker.explorer({ focus = false })
	end
})

vim.api.nvim_create_autocmd('QuitPre', {
	callback = function()
		-- We're quitting a floating window. Do nothing.
		if vim.api.nvim_win_get_config(vim.api.nvim_get_current_win()).relative ~= "" then
			return
		end

		local snacks_windows = {}
		local floating_window_count = 0

		local windows = vim.api.nvim_list_wins()
		for _, w in ipairs(windows) do
			local filetype = vim.api.nvim_get_option_value('filetype', { buf = vim.api.nvim_win_get_buf(w) })
			if filetype:match('snacks_') ~= nil then
				table.insert(snacks_windows, w)
			elseif vim.api.nvim_win_get_config(w).relative ~= '' then
				floating_window_count = floating_window_count + 1
			end
		end

		local remaining_windows = #windows - floating_window_count - #snacks_windows
		if remaining_windows <= 1 then
			for _, w in ipairs(snacks_windows) do
				vim.api.nvim_win_close(w, true)
			end
		end
	end
})
