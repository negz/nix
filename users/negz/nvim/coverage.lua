require('coverage').setup {
	load_coverage_cb = function(ftype)
		vim.notify("Loaded " .. ftype .. " coverage")
	end,
	lang = {
		go = {
			coverage_file = "/tmp/coverage.out"
		},
	}
}
