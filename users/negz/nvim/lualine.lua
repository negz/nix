local snacks_explorer = {
	filetypes = { 'snacks_picker_list' },
	sections = {
		lualine_a = {
			function()
				vim.fn.fnamemodify(vim.fn.getcwd(), ':~')
			end
		}
	},
}

require('lualine').setup {
	options = {
		icons_enabled = true,
		section_separators = ' ',
		component_separators = ' ',
	},
	extensions = { 'trouble', snacks_explorer }
}
