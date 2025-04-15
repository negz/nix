require('neo-tree').setup {
	close_if_last_window = true,
	filesystem = {
		window = {
			position = "right",
		},
		filtered_items = {
			visible = true,
		},
		hijack_netrw_behavior = "open_default",
		follow_current_file = {
			enabled = true,
			leave_dirs_open = true,
		}
	},
	buffers = {
		window = {
			position = "right",
		},
		follow_current_file = {
			enabled = true,
			leave_dirs_open = true,
		}
	},
	git_status = {
		window = {
			position = "right",
		}
	}
}

vim.api.nvim_create_autocmd("UiEnter", {
	callback = function()
		vim.cmd.Neotree("toggle", "action=show")
	end,
})

local command = require('neo-tree.command')
vim.keymap.set('n', '<leader>nf', '<Cmd>Neotree filesystem<Cr>', { desc = 'Neotree filesystem' })
vim.keymap.set('n', '<leader>nb', '<Cmd>Neotree buffers<Cr>', { desc = 'Neotree buffers' })
vim.keymap.set('n', '<leader>ng', '<Cmd>Neotree git_status<Cr>', { desc = 'Neotree git status' })
vim.keymap.set('n', '<leader>nc', '<Cmd>Neotree action=close<Cr>', { desc = 'Close Neotree' })
