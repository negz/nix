local snacks = require('snacks')

snacks.setup {
	dashboard = {
		enabled = true,
		preset = {
			keys = {
				{ icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
				{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
				{ icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
				{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
				{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
			},
		},
		sections = {
			{
				section = "terminal",
				cmd = "chafa --format symbols --size 50x20 --align center ${XDG_DATA_HOME}/nvim/neovim-mark.png; sleep .1",
				height = 25,
				padding = 1,
			},
			{ section = "keys", gap = 1, padding = 1 },
		},

	},
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
			recent = {
				filter = { paths = { [vim.fn.getcwd()] = true } }
			},
			grep = {
				-- Don't OOM me plz.
				limit = 100
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
