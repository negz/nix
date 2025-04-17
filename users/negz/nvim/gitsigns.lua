local signs = require('gitsigns')

signs.setup {
	preview_config = {
		border = "rounded"
	}
}

vim.keymap.set('n', '<leader>gr', signs.reset_hunk, { desc = 'Git reset hunk' })
vim.keymap.set('n', '<leader>gR', signs.reset_buffer, { desc = 'Git reset buffer' })
vim.keymap.set('n', '<leader>gb', signs.blame_line, { desc = 'Git blame line' })
vim.keymap.set('n', '<leader>gB', signs.blame, { desc = 'Git blame file' })
