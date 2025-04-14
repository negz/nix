require('neo-tree').setup {
	vim.api.nvim_create_autocmd("UiEnter", {
		callback = function()
			vim.cmd.Neotree("toggle", "action=show")
		end,
	}),

	close_if_last_window = true,
	filesystem = {
		filtered_items = {
			visible = true,
		},
		hijack_netrw_behavior = "open_default",
		window = {
			position = "right",

		},
		follow_current_file = {
			enabled = true,
			leave_dirs_open = true,
		}
	}
}
