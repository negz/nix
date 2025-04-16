local trouble = require('trouble')

trouble.setup()

local toggle = function(config)
	return function()
		trouble.toggle(config)
	end
end

vim.keymap.set('n', '<leader>dd', toggle({ mode = "diagnostics" }), { desc = 'Toggle Trouble diagnostics' })
vim.keymap.set('n', '<leader>ds', toggle({ mode = "symbols" }), { desc = 'Toggle Trouble symbols' })
vim.keymap.set('n', '<leader>df', toggle({ mode = "quickfix" }), { desc = 'Toggle Trouble quickfix' })
