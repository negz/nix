local wk = require('which-key')

local codewindow = require('codewindow')
local gitsigns = require('gitsigns')
local snacks = require('snacks')
local preview = require('actions-preview')


wk.add({
	{ '<leader>a', group = 'AI' },
	{ '<leader>c', group = 'Code' },
	{ '<leader>f', group = 'Find' },
	{ '<leader>g', group = 'Git' },
	{ '<leader>w', group = 'Window' },
})

local in_cwd = function(picker)
	return function()
		return picker({ filter = { paths = { [vim.fn.getcwd()] = true } } })
	end
end

-- AI
-- Avante adds a bunch of AI stuff under 'a'.

-- Code
vim.keymap.set('n', '<leader>ca', preview.code_actions, { desc = 'Code actions' })
vim.keymap.set('n', '<leader>cd', snacks.picker.lsp_definitions, { desc = 'Go to definition' })
vim.keymap.set('n', '<leader>ci', snacks.picker.diagnostics_buffer, { desc = 'Show buffer diagnostics' })
vim.keymap.set('n', '<leader>cn', vim.lsp.buf.rename, { desc = 'Rename symbol' })
vim.keymap.set('n', '<leader>cr', snacks.picker.lsp_references, { desc = 'Show references' })
vim.keymap.set('n', '<leader>cs', snacks.picker.lsp_symbols, { desc = 'Show buffer symbols' }) -- TODO(negz): Fix weird sort.

-- Find
vim.keymap.set('n', '<leader>fb', snacks.picker.buffers, { desc = 'Find buffers' })
vim.keymap.set('n', '<leader>ff', snacks.picker.files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', snacks.picker.grep, { desc = 'Find strings' })
vim.keymap.set('n', '<leader>fp', snacks.picker.pickers, { desc = 'Find pickers' })
vim.keymap.set('n', '<leader>fr', in_cwd(snacks.picker.recent), { desc = 'Find recent files' })

--- Git
vim.keymap.set('n', '<leader>gb', snacks.picker.git_log_line, { desc = 'Git log line' })
vim.keymap.set('n', '<leader>gl', snacks.picker.git_log, { desc = 'Git log' })
vim.keymap.set('n', '<leader>gr', gitsigns.reset_hunk, { desc = 'Git reset hunk' })
vim.keymap.set('n', '<leader>gR', gitsigns.reset_buffer, { desc = 'Git reset buffer' })
vim.keymap.set('n', '<leader>gs', snacks.picker.git_status, { desc = 'Git status' })

-- Window
vim.keymap.set('n', '<leader>we', snacks.picker.explorer, { desc = 'Toggle explorer' })
vim.keymap.set('n', '<leader>wm', codewindow.toggle_minimap, { desc = 'Toggle minimap' })
vim.keymap.set('n', '<leader>wv', '<Cmd>vsplit<Cr>', { desc = 'Vertical split' })
vim.keymap.set('n', '<leader>w<Left>', '<C-W><Left>', { desc = 'Move left' })
vim.keymap.set('n', '<leader>w<Right>', '<C-W><Right>', { desc = 'Move right' })
