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
			frecency = true,
		}
	},
	quickfile = { enabled = true },
}

local recent = function()
	snacks.picker.recent({ filter = { paths = { [vim.fn.getcwd()] = true } } })
end

vim.keymap.set('n', '<leader>pf', snacks.picker.files, { desc = 'Pick files' })
vim.keymap.set('n', '<leader>pr', recent, { desc = 'Pick recent files' })
vim.keymap.set('n', '<leader>pg', snacks.picker.grep, { desc = 'Pick grep' })
vim.keymap.set('n', '<leader>pb', snacks.picker.buffers, { desc = 'Pick buffers' })
vim.keymap.set('n', '<leader>ps', snacks.picker.git_status, { desc = 'Pick git status' })
vim.keymap.set('n', '<leader>pf', snacks.picker.lsp_references, { desc = 'Pick LSP references' })
vim.keymap.set('n', '<leader>pp', snacks.picker.pickers, { desc = 'Pick pickers' })
