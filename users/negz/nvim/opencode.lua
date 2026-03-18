-- Auto-enter insert mode when entering a terminal buffer.
vim.api.nvim_create_autocmd('BufEnter', {
	pattern = 'term://*',
	callback = function()
		vim.cmd('startinsert')
	end,
})

vim.g.opencode_opts = {
	server = {
		toggle = function()
			require('opencode.terminal').toggle('opencode --port', {
				width = math.floor(vim.o.columns * 0.5),
			})
		end,
	},
	events = {
		reload = true,
		permissions = {
			enabled = false,
		},
	},
}
