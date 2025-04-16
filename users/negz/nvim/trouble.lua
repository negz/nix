local trouble = require('trouble')

trouble.setup()


local diagnostics = function()
	trouble.toggle({ mode = "diagnostics" })
end

local symbols = function()
	trouble.toggle({ mode = "symbols" })
end

local quickfix = function()
	trouble.toggle({ mode = "quickfix" })
end

vim.keymap.set('n', '<leader>dd', diagnostics, { desc = 'Toggle Trouble diagnostics' })
vim.keymap.set('n', '<leader>ds', symbols, { desc = 'Toggle Trouble symbols' })
vim.keymap.set('n', '<leader>df', quickfix, { desc = 'Toggle Trouble quickfix' })
