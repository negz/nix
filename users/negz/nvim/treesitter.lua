require('nvim-treesitter.configs').setup {
	highlight = {
		enable = true,
		additional_vim_regex_highlighting = true
	},
	textobjects = {
		select = {
			enable = true,
			lookahead = true
		}
	}
}
