local wk = require('which-key')

wk.add({
	{ "<leader>p", group = "Pick" },
	{ "<leader>m", group = "Minimap" },
	{ "<leader>d", group = "Diagnostics" },
	{ "<leader>a", group = "AI" },
	{ "<leader>g", group = "Git" },
	{ "<leader>l", group = "Language server" },
})

-- Codewindow minimap.
local codewindow = require('codewindow')

vim.keymap.set('n', '<leader>mt', codewindow.toggle_minimap, { desc = 'Toggle minimap' })

-- Gitsigns
local gitsigns = require('gitsigns')

vim.keymap.set('n', '<leader>gr', gitsigns.reset_hunk, { desc = 'Git reset hunk' })
vim.keymap.set('n', '<leader>gR', gitsigns.reset_buffer, { desc = 'Git reset buffer' })
vim.keymap.set('n', '<leader>gb', gitsigns.blame_line, { desc = 'Git blame line' })
vim.keymap.set('n', '<leader>gB', gitsigns.blame, { desc = 'Git blame file' })

-- Native LSP
vim.keymap.set("n", "<leader>ln", vim.lsp.buf.rename, { desc = "Language server rename" })
vim.keymap.set("n", "<leader>ld", vim.lsp.buf.definition, { desc = "Language server definition" })

-- Snacks picker
local picker = require('snacks').picker
local recent = function()
	picker.recent({ filter = { paths = { [vim.fn.getcwd()] = true } } })
end

vim.keymap.set('n', '<leader>pf', picker.smart, { desc = 'Pick files' })
vim.keymap.set('n', '<leader>pr', recent, { desc = 'Pick recent files' })
vim.keymap.set('n', '<leader>pg', picker.grep, { desc = 'Pick grep' })
vim.keymap.set('n', '<leader>pb', picker.buffers, { desc = 'Pick buffers' })
vim.keymap.set('n', '<leader>ps', picker.git_status, { desc = 'Pick git status' })
vim.keymap.set('n', '<leader>pf', picker.lsp_references, { desc = 'Pick LSP references' })
vim.keymap.set('n', '<leader>pp', picker.pickers, { desc = 'Pick pickers' })

-- TODO(negz): Focus explorer: https://github.com/folke/snacks.nvim/discussions/1273

-- Trouble diagnostics
local trouble = require('trouble')

local toggle = function(config)
	return function()
		trouble.toggle(config)
	end
end

vim.keymap.set('n', '<leader>dd', toggle({ mode = "diagnostics" }), { desc = 'Toggle Trouble diagnostics' })
vim.keymap.set('n', '<leader>ds', toggle({ mode = "symbols" }), { desc = 'Toggle Trouble symbols' })
vim.keymap.set('n', '<leader>df', toggle({ mode = "quickfix" }), { desc = 'Toggle Trouble quickfix' })
