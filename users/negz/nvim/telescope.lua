local telescope = require('telescope')
local builtin = require('telescope.builtin')

telescope.setup()

telescope.load_extension('fzf')
telescope.load_extension('ui-select')
telescope.load_extension('notify')


local oldfiles = function()
	builtin.oldfiles({ only_cwd = true })
end

local pickers = function()
	builtin.builtin({ include_extensions = true })
end

vim.keymap.set('n', '<leader>tf', builtin.find_files, { desc = 'Telescope find files' })
vim.keymap.set('n', '<leader>to', oldfiles, { desc = 'Telescope old files' })
vim.keymap.set('n', '<leader>tg', builtin.live_grep, { desc = 'Telescope live grep' })
vim.keymap.set('n', '<leader>tb', builtin.buffers, { desc = 'Telescope buffers' })
vim.keymap.set('n', '<leader>td', builtin.lsp_definitions, { desc = 'Telescope go to definition' })
vim.keymap.set('n', '<leader>ts', builtin.git_status, { desc = 'Telescope git status' })
vim.keymap.set('n', '<leader>tt', builtin.treesitter, { desc = 'Telescope Treesitter' })
vim.keymap.set('n', '<leader>th', builtin.help_tags, { desc = 'Telescope help tags' })
vim.keymap.set('n', '<leader>tp', pickers, { desc = 'Telescope pickers' })
