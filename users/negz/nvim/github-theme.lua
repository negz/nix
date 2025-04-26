require('github-theme').setup {
	groups = {
		github_light_default = {
			LspSignatureActiveParameter = {
				fg = "red",
				style = "bold",
				bg = "NONE",
			},
			-- Symbols highlighted by snacks.nvim words plugin.
			LspReferenceRead = {
				style = "underline",
				bg = "NONE",
			},
			LspReferenceWrite = {
				style = "underline",
				bg = "NONE",
			},
			LspReferenceText = {
				style = "underline",
				bg = "NONE",
			}
		},
		github_dark_default = {
			LspSignatureActiveParameter = {
				fg = "red",
				style = "bold",
				bg = "NONE",
			},
			-- Symbols highlighted by snacks.nvim words plugin.
			LspReferenceRead = {
				style = "underline",
				bg = "NONE",
			},
			LspReferenceWrite = {
				style = "underline",
				bg = "NONE",
			},
			LspReferenceText = {
				style = "underline",
				bg = "NONE",
			}
		},
	}
}

local toggle = function()
	if vim.o.background == "light" then
		vim.cmd.colorscheme("github_light_default")
	end
	if vim.o.background == "dark" then
		vim.cmd.colorscheme("github_dark_default")
	end
end

vim.api.nvim_create_autocmd("OptionSet", {
	pattern = "background",
	callback = toggle,
})
