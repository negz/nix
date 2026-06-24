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

-- Enable 24-bit truecolor. Without this Neovim falls back to the 256-color
-- palette, which makes the GitHub theme look washed out.
vim.opt.termguicolors = true

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

-- Apply the colorscheme at startup. The OptionSet autocmd above only fires when
-- 'background' changes, which may not happen on a fresh launch, so set it once
-- here based on the current background.
toggle()
