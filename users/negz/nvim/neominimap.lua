vim.g.neominimap = {
	auto_enable = true,
	float = {
		-- Slightly above treesitter-context (which is 20) but below
		-- Snacks pickers.
		z_index = 25,
	},
	search = {
		enabled = true,
	},
	diagnostic = {
		enabled = true,
		mode = "icon",
	},
	git = {
		enabled = true,
	},
}
