local cw = require('codewindow')

cw.setup {
	auto_enable = true,
	show_cursor = false,
	window_border = 'none',
	minimap_width = 15,
	screen_bounds = 'background'
}


vim.keymap.set('n', '<leader>mt', cw.toggle_minimap, { desc = 'Toggle minimap' })
