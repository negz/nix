local coverfile = function(name)
	return vim.fn.stdpath("cache") .. "/" .. name .. "-" .. tostring(vim.fn.getpid())
end


require('coverage').setup {
	auto_reload = true,
	load_coverage_cb = function(ftype)
		vim.notify("Loaded " .. ftype .. " coverage")
	end,
	lang = {
		go = {
			coverage_file = coverfile("coverage-go")
		},
	}
}
