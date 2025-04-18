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
	sections = {
		lualine_b = { 'branch', 'diff', 'lsp_status', 'diagnostics' },
	},
	extensions = { snacks_explorer }
}
