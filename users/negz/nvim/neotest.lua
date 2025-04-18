local neotest = require('neotest')
local golang = require('neotest-golang')
local python = require('neotest-python')

neotest.setup {
	adapters = {
		golang { runner = "gotestsum" },
		python,
	}
}

local run_test = function(args)
	return function()
		neotest.run.run(args)
	end
end


vim.keymap.set('n', '<leader>ta', neotest.run.attach, { desc = 'Attach to test' })
vim.keymap.set('n', '<leader>tf', run_test(vim.fn.expand('%')), { desc = 'Test file' })
vim.keymap.set('n', '<leader>to', neotest.output.open, { desc = 'Show test output' })
vim.keymap.set('n', '<leader>tt', run_test(), { desc = 'Test nearest' })
