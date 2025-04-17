local tree = require('neo-tree')
local command = require('neo-tree.command')

tree.setup {
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

local tcb = function(config)
	return function()
		command.execute(config)
	end
end

vim.api.nvim_create_autocmd("UiEnter", {
	callback = tcb({ action = "show", source = "filesystem" })
})
