require('github-theme').setup {}

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
